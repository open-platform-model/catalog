# Catalog Integration — #DashboardResource

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

---

## Summary

`#DashboardResource` is a new Resource type in the `observability` category of `opm/v1alpha1`, extending `prim.#Resource` to carry typed Grafana dashboard definitions. Dashboards are rendered to Kubernetes ConfigMaps bearing the `grafana_dashboard: "1"` label, which triggers Grafana's sidecar provisioner for automatic discovery.

---

## File Layout

New files to create under `catalog/opm/v1alpha1/`:

```
catalog/opm/v1alpha1/
├── schemas/
│   ├── observability.cue           (Layer 2: #DashboardSchema, panel helpers, query types)
│   ├── observability_patterns.cue  (reusable patterns: #ContainerMetricsRow, #HttpRequestsRow)
│   ├── observability_render.cue    (rendering logic: #RenderDashboard)
│   ├── observability_units.cue     (unit constants: #Units)
│   └── vendor/
│       └── grafana/
│           ├── IMPORT_NOTES.md
│           ├── import.sh
│           ├── dashboard_gen.cue   (Layer 1: generated)
│           ├── common_gen.cue      (Layer 1: generated)
│           └── panels/
│               ├── timeseries_gen.cue
│               ├── stat_gen.cue
│               └── ...
├── resources/
│   └── observability/
│       └── dashboard.cue           (Layer 3: #DashboardResource)
└── blueprints/
    └── observability/              (future: #MonitoringStackBlueprint)
```

Layer 1 files (`*_gen.cue`) are produced by `cue import` and must not be edited by hand. Layer 2 (`observability.cue`, `observability_render.cue`) wraps Layer 1 with OPM-idiomatic types. Layer 3 (`dashboard.cue`) defines the Resource and Component that module authors consume.

---

## #DashboardResource

Full definition in `resources/observability/dashboard.cue`:

```cue
package observability

import (
    prim      "opmodel.dev/core/v1alpha1/primitives@v1"
    component "opmodel.dev/core/v1alpha1/component@v1"
    schemas   "opmodel.dev/opm/v1alpha1/schemas@v1"
)

#DashboardResource: prim.#Resource & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/resources/observability"
        version:     "v1"
        name:        "dashboard"
        description: "Grafana dashboard definitions for a module"
        labels: {
            "resource.opmodel.dev/category": "observability"
        }
    }

    spec: close({
        // Map key becomes dashboard title and ConfigMap suffix
        dashboards: [dashName=string]: schemas.#DashboardSchema & {
            title: string | *dashName
        }
    })

    #defaults: #DashboardDefaults
}

#DashboardDefaults: schemas.#DashboardSchema & {}

#Dashboard: component.#Component & {
    #resources: {
        (#DashboardResource.metadata.fqn): #DashboardResource
    }
}
```

### Field Reference

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `spec.dashboards` | `[string]: #DashboardSchema` | yes | Map of dashboard definitions; key is used as ConfigMap suffix and default title |
| `metadata.labels["resource.opmodel.dev/category"]` | `"observability"` | computed | Category label applied automatically |
| `#defaults` | `#DashboardDefaults` | no | Shared defaults unified into every dashboard in spec |

The map key in `spec.dashboards` serves two purposes: it becomes the ConfigMap name suffix (`grafana-dashboard-<key>`) and the default value for `title` if the author does not set one explicitly.

---

## Rendering: #RenderDashboard

Location: `schemas/observability_render.cue`

`#RenderDashboard` converts a `#DashboardSchema` value into a complete `grafana.#Dashboard`-typed value ready for `json.Marshal`. The output is validated against the imported Grafana schema at `cue vet` time.

```cue
package schemas

import (
    "crypto/sha256"
    "encoding/hex"
    grafana "opmodel.dev/opm/v1alpha1/schemas/vendor/grafana"
)

// #RenderDashboard converts a #DashboardSchema to a grafana.#Dashboard.
// Output is validated against the imported Grafana schema.
#RenderDashboard: {
    // Input
    input:      #DashboardSchema
    moduleFQN?: string  // Used for UID derivation if uid not set

    // Computed UID
    _uid: string
    if input.uid != _|_ {
        _uid: input.uid
    }
    if input.uid == _|_ && moduleFQN != _|_ {
        _uid: hex.Encode(sha256.Sum256("\(moduleFQN):\(input.title)"))[:40]
    }
    if input.uid == _|_ && moduleFQN == _|_ {
        _uid: "dashboard-\(hex.Encode(sha256.Sum256(input.title))[:8])"
    }

    // Output: conforms to grafana.#Dashboard
    output: grafana.#Dashboard & {
        schemaVersion: 42
        uid:           _uid
        title:         input.title
        description:   input.description
        tags:          input.tags
        timezone:      input.timezone
        time:          input.time
        refresh:       input.refresh
        editable:      input.editable
        graphTooltip:  0  // default: off

        // Render panels: assign IDs, compute gridPos
        panels: [ for _id, _name in _panelOrder {
            let _p = input.panels[_name]
            _p & {
                id: _id + 1
                gridPos: _computeGridPos[_id]
            }
        }]

        // Render variables
        templating: list: [ for _name, _v in input.variables { _v } ]
    }
}
```

### Panel Ordering and gridPos Auto-Layout

CUE maps are unordered. Panel ordering follows insertion order in the CUE source file, tracked via `_panelOrder`. The auto-layout algorithm:

1. Track cumulative width across the current row
2. When `cumulativeWidth + panel.w > 24`, wrap to a new row (`y += defaultPanelHeight`)
3. Assign `x = cumulativeWidth`
4. Increment `cumulativeWidth += panel.w`
5. Explicit `gridPos.y` values on a panel override auto-layout for that panel only

Grafana's grid is 24 units wide. Panels that exceed the row boundary wrap rather than overflow.

---

## ConfigMap Rendering

Dashboards render as Kubernetes ConfigMaps in `components.cue`. The `grafana_dashboard: "1"` label triggers Grafana's sidecar provisioner; no custom controller is required.

Pattern in `components.cue`:

```cue
import (
    "encoding/json"
    schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

configMaps: {
    for _name, _dash in spec.dashboards {
        "grafana-dashboard-\(_name)": {
            metadata: labels: {
                "grafana_dashboard":                  "1"
                "app.kubernetes.io/managed-by":       "opm"
            }
            data: {
                "\(_name).json": json.Marshal(
                    (schemas.#RenderDashboard & {
                        input:     _dash
                        moduleFQN: metadata.fqn
                    }).output
                )
            }
        }
    }
}
```

One ConfigMap is emitted per entry in `spec.dashboards`. The ConfigMap name is `grafana-dashboard-<key>` and the data key is `<key>.json`. Both are derived from the map key in `spec.dashboards`.

---

## Grafana Sidecar Discovery

How the ConfigMap reaches Grafana — standard sidecar pattern, no custom controller required:

```yaml
# Grafana Helm values (reference only — not part of OPM)
grafana:
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      labelValue: "1"
      searchNamespace: ALL
```

The sidecar watches for ConfigMaps with `grafana_dashboard: "1"` across all namespaces and auto-provisions them into Grafana at runtime. No Grafana restart is required when a ConfigMap is added, updated, or removed.

`searchNamespace: ALL` is required when module workloads run in namespaces other than the Grafana namespace. Restrict to specific namespaces if the cluster policy does not permit cross-namespace sidecar watch.

---

## Index Update

Add to `catalog/opm/v1alpha1/INDEX.md` after implementation:

```markdown
### Observability

| Type | Name | Description |
| ---- | ---- | ----------- |
| Resource | dashboard | Grafana dashboard definitions for a module |
```

Run `task -C catalog generate:index` to regenerate all INDEX.md files automatically. If the task is unavailable, edit manually and verify with `task -C catalog generate:index:check`.

---

## Version Bump

Adding a new resource category to `opm/v1alpha1` is a breaking change to the module's public API surface. Existing consumers that import `opm/v1alpha1` will pick up the new `observability` package on their next `cue mod tidy`. A major version bump is required.

```bash
task -C catalog version:bump DOMAIN=opm TYPE=major
task -C catalog publish:smart
task update-deps  # from workspace root
```

Run `task update-deps` from the workspace root after publishing to propagate the new version pin into `cli/examples`, `poc-controller`, `modules`, and `releases`. Do not manually edit `cue.mod/module.cue` version pins.

---

## Verification Checklist

Run after completing implementation:

- [ ] `task -C catalog fmt` — no formatting changes
- [ ] `task -C catalog vet` — no evaluation errors
- [ ] `task -C catalog vet CONCRETE=true` — value-producing definitions are concrete
- [ ] `task -C catalog vet:examples` — examples pass with new schemas in scope
- [ ] `task -C catalog test` — all CUE tests pass
- [ ] `cue vet` a real Grafana dashboard JSON against `dashboard_gen.cue`
- [ ] Confirm `grafana_dashboard: "1"` label present on rendered ConfigMap
- [ ] Confirm UID is deterministic across two identical renders
- [ ] `task -C catalog generate:index:check` — INDEX.md is up to date
