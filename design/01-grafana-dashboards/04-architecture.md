# Three-Layer Schema Architecture

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

## Summary

Grafana dashboard support uses a three-layer schema architecture in which each layer constrains the one below via CUE unification. Any dashboard defined at Layer 2 is guaranteed to produce valid Grafana JSON because it must satisfy Layer 1's imported base types at definition time.

## Layer Overview

```
Layer 3: #DashboardResource  (OPM resource type, published in opm/v1alpha1)
             |
             | unifies with
             v
Layer 2: #DashboardSchema, #TimeseriesPanel, #StatPanel, ...
         (opinionated wrappers with defaults, published in opm/v1alpha1/schemas)
             |
             | unifies with
             v
Layer 1: grafana.#Dashboard, grafana.#TimeseriesPanel, ...
         (imported from Grafana JSON Schema via cue import, vendored)
```

CUE unification means: a value that satisfies Layer 2 automatically satisfies Layer 1. If Layer 2 introduces a field that contradicts Layer 1's constraints, `cue vet` fails at definition time — before any rendering occurs.

## Layer 1: Imported Base Schema

- Location: `catalog/opm/v1alpha1/schemas/vendor/grafana/`
- Package: `grafana` (internal, not exported as a catalog module)
- Files: `dashboard_gen.cue`, `common_gen.cue`, `panels/*_gen.cue`
- Generated via `cue import` from Foundation SDK JSON Schema
- Never hand-edit generated files
- Re-import on major Grafana releases (see `03-cue-import-strategy.md`)
- Provides: `grafana.#Dashboard`, `grafana.#TimeseriesPanel`, `grafana.#StatPanel`, etc.

## Layer 2: Opinionated Wrappers

Location: `catalog/opm/v1alpha1/schemas/observability.cue`
Package: `schemas` (published as part of `opm/v1alpha1`)

### #DashboardSchema

```cue
#DashboardSchema: grafana.#Dashboard & {
    // Required: dashboard title
    title!: string

    // Optional: auto-derived from module FQN + dashboard name if omitted
    // Derivation: SHA-256("<module_fqn>:<dashboard_name>")[:40]
    uid?: string

    description?: string
    tags?:        [...string]
    timezone:     *"browser" | "utc" | string
    time: {
        from: string | *"now-6h"
        to:   string | *"now"
    }
    refresh?:           string
    editable:           *true | false
    defaultPanelHeight: uint & >0 | *8

    // Map-based panels: key becomes panel title default
    panels: [panelName=string]: #Panel & {
        title: string | *panelName
    }

    // Map-based variables: key becomes variable name default
    variables?: [varName=string]: #Variable & {
        name: string | *varName
    }
}
```

### Panel Helpers

Each helper embeds the corresponding Layer 1 type and sets opinionated defaults. The `type` discriminator is fixed at each wrapper so `cue vet` rejects mismatched panel configurations.

```cue
#TimeseriesPanel: grafana.#TimeseriesPanel & {
    type: "timeseries"
    gridPos: #GridPos
    options: {
        legend: {
            displayMode: *"list" | "table" | "hidden"
            placement:   *"bottom" | "right"
        }
        tooltip: {
            mode: *"single" | "multi" | "none"
        }
    }
    fieldConfig: defaults: custom: {
        drawStyle:   *"line" | "bars" | "points"
        fillOpacity: *10 | number
        lineWidth:   *2 | number
        stacking: mode: *"none" | "normal" | "percent"
    }
}

#StatPanel: grafana.#StatPanel & {
    type: "stat"
    gridPos: #GridPos
    options: {
        colorMode:   *"value" | "none" | "background"
        graphMode:   *"area" | "none"
        textMode:    *"auto" | string
        reduceOptions: {
            values: *false | true
            calcs:  [...string] | *["lastNotNull"]
        }
    }
}

#GaugePanel: grafana.#GaugePanel & {
    type: "gauge"
    gridPos: #GridPos
    options: {
        orientation:         *"auto" | "horizontal" | "vertical"
        gaugeType:           *"gauge" | "donut"
        showThresholdLabels: *false | true
    }
}

#TablePanel: grafana.#TablePanel & {
    type: "table"
    gridPos: #GridPos
    options: {
        showHeader: *true | false
        sortBy:     *[] | [..._]
        pagination: pageSize: *10 | uint
    }
}

#TextPanel: {
    type: "text"
    gridPos: #GridPos
    options: {
        mode:    *"markdown" | "html"
        content: string
    }
}

#LogsPanel: grafana.#LogsPanel & {
    type: "logs"
    gridPos: #GridPos
    options: {
        showLabels:         *true | false
        showTime:           *true | false
        wrapLogMessage:     *false | true
        prettifyLogMessage: *false | true
    }
}
```

### Query Types

```cue
// Typed Prometheus query
#PromQLTarget: {
    expr!:           string        // PromQL expression (required)
    refId:           string | *"A"
    legendFormat?:   string
    format:          *"time_series" | "table" | "heatmap"
    instant?:        bool
    intervalFactor?: number
    exemplar?:       bool
}

// Open escape hatch for any datasource
#GenericTarget: {
    refId: string
    ...
}

// Datasource reference
#DataSourceRef: {
    type?: string  // e.g. "prometheus", "loki", "elasticsearch"
    uid?:  string  // datasource UID
}
```

### #GridPos with Defaults

```cue
#GridPos: {
    h: uint & >0         | *8
    w: uint & >0 & <=24  | *12
    x: uint & >=0 & <24  | *0
    y: uint & >=0        | *0
}
```

### Escape Hatch

Every panel type exposes `_rawOverrides` for fields not modeled in Layer 2:

```cue
#Panel: {
    // ... typed fields ...
    _rawOverrides?: {...}  // Merged into final JSON output during rendering
}
```

`_rawOverrides` fields take precedence over typed fields during rendering. This allows any valid Grafana panel option to be expressed without requiring a Layer 2 update. Use `_rawOverrides` only for fields that are not modeled; prefer typed fields wherever they exist.

## Layer 3: OPM Resource

Location: `catalog/opm/v1alpha1/resources/observability/dashboard.cue`
Package: `observability`

```cue
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

`spec` is closed: unknown keys at the `dashboards` map level are rejected by `cue vet`. Individual dashboard entries remain open at the `#DashboardSchema` level until the escape hatch is explicitly invoked.

## CUE Unification Guarantee

When a module author writes:

```cue
spec: dashboards: {
    "my-dashboard": {
        title: "My App"
        panels: {
            "request-rate": schemas.#TimeseriesPanel & {
                targets: [schemas.#PromQLTarget & {
                    expr: "rate(http_requests_total[5m])"
                }]
            }
        }
    }
}
```

CUE evaluates the unification chain in order:

1. `#PromQLTarget` constrains `expr` to string — checked
2. `#TimeseriesPanel` constrains `type` to `"timeseries"` — checked
3. `grafana.#TimeseriesPanel` (Layer 1) validates all panel fields — checked
4. `#DashboardSchema` constrains `title` to string — checked
5. `grafana.#Dashboard` (Layer 1) validates all dashboard fields — checked

If any field violates a constraint at any layer, `cue vet` fails before any rendering occurs. Invalid dashboards cannot be published.

## What Is NOT Modeled

The following require `_rawOverrides` and are deferred to future work:

- Grafana Alerting rules (see `08-decisions.md`)
- Plugin-specific panel options for rarely-used panel types: `canvas`, `nodeGraph`, `flamegraph`, `traces`
- Grafana actions (fetch/infinity type)
- Snapshot-specific fields
