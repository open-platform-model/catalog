# RFC-0003: Bundle System

| Field        | Value                              |
|--------------|------------------------------------|
| **Status**   | Draft                              |
| **Created**  | 2026-03-02                         |
| **Authors**  | OPM Contributors                   |

## Summary

Redesign `#Bundle` as OPM's composition and coordination layer for complex, multi-module deployments. Bundles group modules into a flat structure with per-instance namespace control, explicit values wiring, bundle-level policies, and CUE comprehension-based dynamic composition. Standalone `#ModuleRelease` remains the primary path for single-application deployments.

Introduce `#BundleRelease` which resolves a bundle into a flat map of `#ModuleRelease` instances — feeding directly into the existing provider/transformer pipeline with zero changes downstream.

The key design insight: since OPM modules are CUE structural references (not opaque artifacts), bundle authors can reference module `#config` schemas directly in `#BundleInstance.values`, and CUE validates all wiring at definition time. This gives OPM bundles significantly more power than Timoni or Helm umbrella charts, where module/chart references are external and opaque.

`#BundleInstance` is designed as a mini-release: each instance carries a module reference, metadata (name, namespace, labels, annotations), and optional values wiring. This mirrors the structure of `#ModuleRelease` and makes each instance's intent self-contained and readable.

## Motivation

### Current State

OPM's delivery flow is `Module → ModuleRelease → Provider → platform resources`. This works for single applications but has concrete gaps:

1. **No multi-module coordination.** Deploying an observability stack (Grafana + Prometheus + log collection) requires creating independent ModuleReleases with no formal mechanism to share config (database passwords, service URLs) or express deployment ordering.

2. **No cross-module governance.** Policies exist at the module level (`#Module.#policies`) but cannot span modules. There is no way to express "these three modules should share a network policy" without duplicating the policy in each module.

3. **No dynamic composition.** A Module's `#components` map is fixed at authoring time. There is no way to instantiate N copies of a module from a config schema (e.g., N game servers, N tenant environments).

4. **No multi-namespace deployment.** Each `#ModuleRelease` targets a single namespace. Deploying a system that spans namespaces (`monitoring`, `logging`, `cert-manager`) requires N independent releases with no shared config surface.

5. **No platform composition.** Large platforms composed of area-specific bundles (core, auth, observability, databases, AI) have no formal model. Platform topology lives in documentation and CI scripts, not in validated CUE definitions.

```text
┌───────────────────────────────────────────────────────────────────┐
│                    OPM Today                                      │
│                                                                   │
│  Module A ──▶ ModuleRelease A  ──▶ namespace: monitoring        │
│  Module B ──▶ ModuleRelease B  ──▶ namespace: monitoring        │
│  Module C ──▶ ModuleRelease C  ──▶ namespace: logging           │
│                                                                   │
│  Shared config? Manual duplication.                               │
│  Network policy? Duplicated in each module.                       │
│  Deployment ordering? External scripts.                           │
│  "These belong together"? Not expressible.                        │
└───────────────────────────────────────────────────────────────────┘
```

### The Multi-Module Problem

The core motivating scenario: deploying a system of related modules that need coordinated configuration, governance, and deployment.

```text
┌──────────────────────────────────────────────────────────────────────┐
│  MULTI-MODULE SCENARIO: Observability Stack                          │
│                                                                      │
│  ┌───────────────────┐  ┌───────────────────┐  ┌──────────────────┐  │
│  │ grafana-operator  │  │ prometheus-op     │  │ log-collector    │  │
│  │ ns: monitoring    │  │ ns: monitoring    │  │ ns: logging      │  │
│  └───────────────────┘  └───────────────────┘  └──────────────────┘  │
│           │                      │                      │            │
│           └──────── shared config ──────────────────────┘            │
│           │                      │                      │            │
│           └──── network policy: allow prometheus ───────┘            │
│           │                      │                      │            │
│           └── grafana datasource URL = prometheus svc ──┘            │
│                                                                      │
│  Desired:                                                            │
│  1. Define all three as ONE deployable unit                          │
│  2. Shared config: storage class, retention, domain                  │
│  3. Cross-module network policy                                      │
│  4. Bundle author wires grafana → prometheus URL                     │
│  5. Consumer provides: storageClass, retention, domain               │
│  6. Each module gets its own namespace                               │
└──────────────────────────────────────────────────────────────────────┘
```

### Why Bundles for Complex Deployments

Bundles enable capabilities that standalone modules cannot provide, making them essential for complex, multi-module systems:

- **Dynamic composition** via CUE for-loops (N module instances from config)
- **Cross-module config wiring** (shared secrets, service URLs)
- **Cross-module policies** (network rules spanning modules)
- **Multi-namespace deployments** (each module in its own namespace)
- **Coordinated versioning** of module sets tested together
- **Platform composition** from area-specific bundles

For single-application deployments, standalone `#ModuleRelease` remains the simplest and recommended path. Bundles are designed for complex, multi-module systems — platforms, curated stacks, and dynamic multi-instance deployments — where coordination, cross-module wiring, and multi-namespace support are needed.

### Why Now

The existing `#Bundle` skeleton in `core/bundle.cue` was never fully designed. The core module types (`#Module`, `#ModuleRelease`, `#Component`, `#Policy`) are stabilizing. Adding the bundle system now — before a broader ecosystem exists — avoids a disruptive migration later.

## Prior Art

### Timoni Bundles

Timoni is the closest architectural analog to OPM. Timoni bundles use an `instances` map where each entry carries a module reference, namespace, and values:

```cue
bundle: {
    apiVersion: "v1alpha1"
    name:       "podinfo"
    instances: {
        redis: {
            module: {
                url:     "oci://ghcr.io/stefanprodan/modules/redis"
                version: "7.2.4"
            }
            namespace: "podinfo"
            values:    maxmemory: 256
        }
        podinfo: {
            module: {
                url:     "oci://ghcr.io/stefanprodan/modules/podinfo"
                version: "6.5.4"
            }
            namespace: "podinfo"
            values: caching: {
                enabled:  true
                redisURL: "tcp://redis:6379"
            }
        }
    }
}
```

**Key design choices:**

- Module references are OCI URLs (external, fetched at apply time)
- Values are per-instance (no centralized config schema)
- Flat structure only (no bundle nesting)
- No cross-instance policies
- No for-loop composition (each instance is hand-written)
- Namespace is per-instance (required field)

**Relevance to OPM:**

- The `{module, namespace, values}` instance pattern is directly adopted by OPM as `#BundleInstance` — same structure, same intent
- OPM diverges by using CUE structural references (not opaque OCI URLs), enabling cross-module field references and compile-time validation of `values` against `module.#config`
- OPM adds centralized `#config` at the bundle level for the consumer-facing schema, with explicit wiring to module instance `values`
- OPM adds bundle-level policies and CUE comprehension-based dynamic composition

### Helm Umbrella Charts

Helm umbrella charts are the most widely used multi-chart composition mechanism. An umbrella chart declares sub-charts as dependencies and exposes a unified `values.yaml`:

```yaml
# Chart.yaml
dependencies:
  - name: grafana
    version: 6.50.0
    repository: https://grafana.github.io/helm-charts
  - name: prometheus
    version: 25.0.0
    repository: https://prometheus-community.github.io/helm-charts
```

**Key design choices:**

- Sub-charts are external references (repository + version)
- Values cascade: parent `values.yaml` can override sub-chart values by key (`grafana.persistence.enabled: true`)
- Flat structure (umbrella of umbrellas is possible but not a first-class pattern)
- No cross-chart policies or governance
- No dynamic composition
- All sub-charts deploy to the same namespace (Helm limitation)

**Relevance to OPM:**

- Validates the pattern of centralized config that cascades to sub-modules
- OPM's explicit wiring (via CUE unification) is more transparent than Helm's implicit key-based cascading
- OPM's per-instance namespace is a significant improvement over Helm's single-namespace constraint

### Comparison

```text
┌──────────────────────┬──────────────────┬──────────────────┬──────────────────┐
│                      │ Timoni Bundles   │ Helm Umbrella    │ OPM Bundle       │
├──────────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Module reference     │ OCI URL          │ Chart dependency │ CUE struct ref   │
│ Config model         │ Per-instance     │ Cascading values │ Central + wiring │
│ Namespace control    │ Per-instance     │ Single namespace │ Per-instance     │
│ Nesting              │ [ ]              │ [ ] (ad hoc)     │ [ ] (flat)       │
│ Cross-module policy  │ [ ]              │ [ ]              │ [x]              │
│ Dynamic composition  │ [ ]              │ [ ]              │ [x] CUE for-loop │
│ Compile-time valid.  │ CUE (partial)    │ [ ]              │ [x] Full CUE     │
│ Cross-module refs    │ [ ] (hardcoded)  │ [ ] (hardcoded)  │ [x] CUE refs     │
│ Schema validation    │ CUE              │ JSON Schema      │ CUE              │
└──────────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

## Design

### Overview

The bundle system introduces three new types and revises the existing `#Bundle`:

```text
┌─────────────────────────────────────────────────────────────────────┐
│                       Bundle System                                  │
│                                                                      │
│  #BundleInstance   Mini-release: {module, metadata, values?}         │
│  #Bundle           Flat container: instances + config + policies     │
│  #BundleRelease    Concrete deployment: produces ModuleReleases      │
│                                                                      │
│  Existing types (unchanged):                                         │
│  #Module, #ModuleRelease, #Component, #Policy, #Provider            │
│                                                                      │
│  Flow:                                                               │
│  Bundle Author ──defines──▶ #Bundle                                 │
│  Consumer      ──deploys──▶ #BundleRelease                          │
│  Pipeline      ──renders──▶ flat map of #ModuleRelease              │
│                                ▼                                     │
│                     existing provider/transformer pipeline           │
└─────────────────────────────────────────────────────────────────────┘
```

### `#BundleInstance`

Each entry within a bundle is a mini-release: it carries a module reference, per-instance metadata, and optional values wiring. This mirrors `#ModuleRelease` in structure and makes each instance's intent self-contained and readable.

```cue
#BundleInstance: {
    module!: #Module
    metadata: {
        // name is auto-derived from the #instances map key — do not set manually.
        name!:      #NameType

        // namespace is the target Kubernetes namespace for this module instance.
        namespace!: #NameType

        // Optional labels inherited by all resources in this module instance.
        labels?:      #LabelsAnnotationsType

        // Optional annotations inherited by all resources in this module instance.
        annotations?: #LabelsAnnotationsType
    }

    // values wires config into the module's #config schema.
    // If omitted, module defaults apply.
    values?: module.#config
}
```

| Field                | Required | Purpose                                                     |
|----------------------|----------|-------------------------------------------------------------|
| `module`             | Yes      | The module to include as an instance                        |
| `metadata.name`      | Yes      | Auto-derived from the `#instances` map key                  |
| `metadata.namespace` | Yes      | Target Kubernetes namespace for this module instance        |
| `metadata.labels`    | No       | Labels inherited by all resources in this instance          |
| `metadata.annotations` | No     | Annotations inherited by all resources in this instance     |
| `values`             | No       | Config values satisfying the module's `#config` schema      |

**`metadata.name` is auto-derived** from the `#instances` map key via the `#Bundle` constraint:

```cue
#instances!: [Name=string]: #BundleInstance & {metadata: name: Name}
```

The bundle author never sets `metadata.name` manually. The key IS the name.

**`metadata.namespace` is required** on every instance. The bundle author is responsible for selecting the deployment namespace. Consumer-level namespace override is deferred (see [Deferred Work](#deferred-work)).

**Values wiring:** Three patterns are supported — the bundle author chooses based on how much control they want to expose to consumers:

```cue
// Pattern 1: Hardcode — consumer cannot override
server: {
    module:             myModule
    metadata: namespace: "my-ns"
    values: { replicas: 3 }
}

// Pattern 2: Wire from bundle #config — consumer sets via bundle values
server: {
    module:             myModule
    metadata: namespace: C.namespace
    values: { replicas: C.replicas }
}

// Pattern 3: Passthrough — expose full module schema to consumer
server: {
    module:             myModule
    metadata: namespace: C.namespace
    values:             C.myServer  // where C.myServer: myModule.#config in bundle #config
}
```

**Values type constraint:** `values?: module.#config` means CUE validates the values against the module's declared `#config` schema at definition time. Providing a value that violates the module's constraints is a CUE evaluation error — the same guarantee that `#ModuleRelease.values` provides for standalone releases.

The field is named `#instances` to signal these are instantiations. The same module MAY appear multiple times in the same bundle under different instance names (e.g., the Minecraft multi-server pattern).

### `#Bundle` (Revised)

```cue
#Bundle: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Bundle"

    metadata: {
        modulePath!:  #ModulePathType
        name!:        #NameType
        version!:     #MajorVersionType
        fqn:          #ModuleFQNType & "\(modulePath)/\(name):\(version)"
        uuid:         #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)
        #definitionName: (#KebabToPascal & {"in": name}).out

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Instances in this bundle — metadata.name is auto-derived from the map key.
    #instances!: [Name=string]: #BundleInstance & {metadata: name: Name}

    // Bundle-level config schema — consumer-facing.
    // Bundle author wires this into instance values.
    #config!: _

    // Bundle-level policies — cross-module governance
    #policies?: [string]: #Policy

    // Debug/test values
    debugValues: _
}
```

**Key properties:**

- **Flat**: `#instances` contains only module instances — no nested bundles
- **Required**: `#instances` is required — a bundle must contain at least one instance
- **Name auto-derived**: `metadata.name` on each instance is set automatically from the map key
- **Namespace required**: Every instance must declare `metadata.namespace`

### `#BundleRelease`

```cue
#BundleRelease: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "BundleRelease"

    metadata: {
        name!:        #NameType
        uuid:         #UUIDType & cue_uuid.SHA1(OPMNamespace, "\(#bundleMetadata.uuid):\(name)")
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #bundle!:        #Bundle
    #bundleMetadata: #bundle.metadata

    // Concrete values satisfying #bundle.#config
    values: _

    // Output: each #BundleInstance becomes a #ModuleRelease.
    // Keys are the instance names from #bundle.#instances.
    // Release name: "{bundleReleaseName}-{instanceName}"
    releases: [string]: #ModuleRelease
}
```

**Release key rules:**

1. Each key equals the instance name from `#bundle.#instances`
2. Release `metadata.name` is `"{bundleReleaseName}-{instanceName}"`
3. CUE unification catches key collisions at definition time

```text
┌──────────────────────────────────────────────────────────────────────────┐
│  BUNDLE RELEASE RESOLUTION                                               │
│                                                                          │
│  Input:                                                                  │
│    gamestack bundle                                                      │
│    └── #instances:                                                       │
│          server: { module: mc, metadata: { namespace: "game-stack" },   │
│                    values: { maxPlayers: C.maxPlayers, ... } }           │
│          proxy:  { module: vel, metadata: { namespace: "game-stack" },  │
│                    values: { maxPlayers: C.maxPlayers, ... } }           │
│                                                                          │
│  BundleRelease: name "my-game-stack", values: { maxPlayers: 50 }        │
│                                                                          │
│  Output (releases):                                                      │
│    server: #ModuleRelease { name: "my-game-stack-server",               │
│                             namespace: "game-stack", values: {...} }    │
│    proxy:  #ModuleRelease { name: "my-game-stack-proxy",                │
│                             namespace: "game-stack", values: {...} }    │
│                                                                          │
│  Every key is a valid #NameType (kebab-case, max 63 chars).             │
└──────────────────────────────────────────────────────────────────────────┘
```

### Config Wiring

Bundle authors wire `#bundle.#config` into module instances via the `values` field on each `#BundleInstance`. There is no automatic config cascading — all wiring is explicit and validated by CUE at definition time.

The `C=#config` alias at package scope is used to reference the bundle's own `#config` inside `#instances` without ambiguity:

```cue
C=#config: {
    storageClass: string | *"standard"
    retention:    string | *"30d"
    domain?:      string
}

#instances: {
    prometheus: {
        module:             prometheusModule
        metadata: namespace: "monitoring"
        values: {
            storage: storageClass: C.storageClass
            retention:             C.retention
        }
    }
    grafana: {
        module:             grafanaModule
        metadata: namespace: "monitoring"
        values: {
            datasources: prometheus: url: "http://prometheus-server.monitoring:9090"
        }
    }
}
```

Config wiring is per-instance and explicit. There is no hidden magic: every field the module receives is traceable to a `values` entry in the instance definition.

### Cross-Module Policies

Bundles support `#policies` using the existing `#Policy` type. `appliesTo.matchLabels` matches components across all modules in the bundle — labels are inherited from resources and traits, so label-based selection works regardless of which module owns the component.

```cue
observabilityStack: #Bundle & {
    #instances: { /* ... */ }

    #policies: {
        "observability-network": network.#SharedNetwork & {
            appliesTo: matchLabels: {
                "bundle.opmodel.dev/name": "observability-stack"
            }
            spec: sharedNetwork: {}
        }
    }
}
```

Policy scope resolution for nested bundles (does a parent bundle's policy apply to all nested components?) is deferred for separate design.

### Dynamic Composition (For-Loops)

CUE comprehensions in `#instances` enable dynamic module instantiation from config. Each generated entry is a full `#BundleInstance` with `metadata` and `values`:

```cue
C=#config: {
    servers: [string]: {
        gameMode:   "survival" | "creative" | *"survival"
        maxPlayers: int | *20
        memory:     string | *"2Gi"
    }
}

#instances: {
    for serverName, cfg in C.servers {
        (serverName): {
            module:             minecraftServerModule
            metadata: namespace: "mc-\(serverName)"
            values: {
                gameMode:   cfg.gameMode
                maxPlayers: cfg.maxPlayers
                memory:     cfg.memory
            }
        }
    }
}

debugValues: servers: {
    lobby:    { gameMode: "creative", maxPlayers: 100, memory: "4Gi" }
    survival: { gameMode: "survival", maxPlayers: 50 }
    creative: { gameMode: "creative", maxPlayers: 30 }
}
```

This generates three module releases from one module definition. Each instance gets its own namespace, its own `values`, and its own `#ModuleRelease` in the output.

Note: similar dynamic composition is possible within a module using for-loops over `#components`. The difference:

| | Module for-loop (components) | Bundle for-loop (instances) |
|---|---|---|
| Unit generated | Components | Module instances |
| Namespace | Shared (one namespace) | Independent (per-instance) |
| Lifecycle | One release, one lifecycle | Separate releases |
| Use case | N workers in one app | N independent instances |

### Dependencies

CUE imports naturally encode the dependency graph between modules used in a bundle. When a bundle author imports a module package, the CUE module dependency is explicit at the language level:

```cue
import (
    mc  "opmodel.dev/examples/modules/minecraft@v1"
    vel "opmodel.dev/examples/modules/velocity@v1"
)

// CUE import = implicit dependency on both modules.
// The CLI/orchestrator can derive the deployment graph from CUE's module dependency tree.
// No separate `dependsOn` metadata needed.
#instances: {
    server: {
        module:             mc
        metadata: namespace: C.namespace
        values: { /* ... */ }
    }
    proxy: {
        module:             vel
        metadata: namespace: C.namespace
        values: { /* ... */ }
    }
}
```

The CUE import of each module package makes the dependency explicit at the language level.

## Decisions

### D1: Bundle Structure — Flat vs Recursive

**Context**: Bundles need to support module groupings (observability stack, game server, etc.) with clear, readable authoring.

**Options considered:**

1. **Flat** — Bundle contains only Modules. Platform composition is external.
2. **Recursive** — Bundle contains Modules and/or other Bundles.
3. **Flat with external deps** — Bundle contains only Modules but declares `dependsOn` other Bundles by name.

**Decision**: Option 1 — Flat.

**Rationale**: Nested bundles introduce hidden config cascade complexity, ambiguous namespace semantics (does a parent namespace override override a child bundle's internal choices?), and make the dependency graph harder to trace. The bundle as a mini-release design (each instance is a self-contained `{module, metadata, values}` triple) is cleaner and consistent with how `#ModuleRelease` works. Platform-level composition can be achieved by importing and referencing modules from multiple CUE packages directly. Flat structure is Timoni-compatible and easier to reason about.

### D2: Entry Type — Mini-Release vs Bare Reference

**Context**: Bundles need per-entry metadata (at minimum: namespace). The original design had bare `{ module?, bundle?, namespace? }`. The redesign elevates each entry to a mini-release.

**Options considered:**

1. **Bare fields** — `{ module!, namespace? }` — minimal, no nesting.
2. **Mini-release wrapper** — `{ module!, metadata: { name!, namespace!, labels?, annotations? }, values? }` — mirrors `#ModuleRelease`.

**Decision**: Option 2 — Mini-release wrapper (`#BundleInstance`).

**Rationale**: Mirroring `#ModuleRelease` makes instances predictable and self-contained. Bundle authors write the same kind of definition for an instance as consumers write for a standalone release. The `values` field provides an explicit, type-safe config wiring channel — validated against `module.#config` at definition time. `metadata.namespace!` being required prevents silent misconfiguration that would only surface at deploy time. `metadata.name` auto-derived from the map key eliminates redundancy while preserving the ability to reference it in release name generation.

### D3: BundleRelease Output — Map of ModuleReleases

**Context**: `#BundleRelease` resolves a bundle with concrete values. The output must be consumable by the existing provider/transformer pipeline.

**Decision**: Output is `[string]: #ModuleRelease`. Keys equal the instance names from `#bundle.#instances`. Release names are `"{bundleReleaseName}-{instanceName}"`.

**Rationale**: The provider/transformer pipeline operates on `#ModuleRelease`. A flat map is the simplest interface for the downstream engine. Key collisions within a single flat bundle are caught by CUE unification at definition time.

### D4: Namespace Assignment

**Context**: Namespace must be set on every `#ModuleRelease`. Where does it come from in the bundle flow?

**Decision**: `metadata.namespace!` is required on every `#BundleInstance`. The bundle author is the authoritative source.

**Rationale**: The bundle author designs the composition — they know which namespace each module instance belongs in. Making it required at the instance level surfaces the decision explicitly in the bundle definition, rather than relying on module defaults that may be wrong for the bundle context. Consumer-level namespace override is deferred (see [Deferred Work](#deferred-work)).

### D5: Config Pattern — Values on Instance

**Context**: Bundle `#config` defines the consumer-facing schema. Module `#config` defines each module's schema. How do values flow from bundle consumer → module instance?

**Options considered:**

1. **Inline unification** — `module: mc & { #config: { field: #config.value } }` inside the instance.
2. **Explicit `values` field** — `values: { field: C.value }` on the instance, constrained to `module.#config`.

**Decision**: Option 2 — Explicit `values` field on `#BundleInstance`.

**Rationale**: Inline unification (`mc & { #config: {...} }`) is idiomatic CUE but obscures intent: the module reference and the config wiring are tangled together. The `values` field separates them cleanly — `module` is a pure reference, `values` is explicit config. The type constraint `values?: module.#config` validates wiring against the module schema at definition time, catching mismatches immediately. The three wiring patterns (hardcode, wire from bundle #config, passthrough) are all natural expressions of the `values` field and cover the full authoring flexibility spectrum.

### D6: Bundle-Level Policies

**Context**: Modules define `#policies` for intra-module governance. Bundles need cross-module governance.

**Decision**: Bundles get `#policies?: [string]: #Policy` using the existing `#Policy` type.

**Rationale**: `appliesTo.matchLabels` naturally works across modules — it matches any component whose labels satisfy the selector. No changes to `#Policy` needed.

### D7: Release Key Format

**Context**: `#BundleRelease.releases` needs unique keys derived from instance names.

**Decision**: Keys equal the instance name directly from `#bundle.#instances`. Release `metadata.name` is `"{bundleReleaseName}-{instanceName}"`.

**Examples:**

- Instance `grafana` → key: `grafana`, release name: `"my-obs-grafana"`
- Instance `server` → key: `server`, release name: `"my-game-stack-server"`

**Rationale**: Simple and consistent. Collisions within a bundle are caught by CUE at definition time. The release name prefixing (`{bundleReleaseName}-`) ensures globally unique names across bundle releases.

### D8: Bundle Positioning — Complex Deployments

**Context**: Should Bundle be positioned as the primary deployment unit for all cases, or scoped to complex multi-module scenarios?

**Decision**: Bundles are the composition and coordination layer for complex deployments. Standalone `#ModuleRelease` remains the primary path for single-application deployments.

**Rationale**: Bundles add value when there is cross-module coordination (shared config, policies, multi-namespace, dynamic composition). For a single application with one module and one namespace, `#ModuleRelease` is simpler and sufficient. Bundles shine for platforms, curated stacks, and multi-instance patterns. The flow depends on complexity: simple apps use `Module Author → Consumer (ModuleRelease)`, complex systems use `Module Author → Bundle Author → Consumer (BundleRelease)`.

### D9: Instance Name — Map Key vs Explicit Field

**Context**: Each instance needs a name for release name generation. The `#instances` map already has a string key. Should `metadata.name` be auto-derived or explicitly required?

**Decision**: `metadata.name` is auto-derived from the `#instances` map key via the `#Bundle` constraint: `#instances!: [Name=string]: #BundleInstance & {metadata: name: Name}`.

**Rationale**: The key IS the canonical instance name. Requiring it again in `metadata.name` would create redundancy and the possibility of key ≠ name inconsistencies. Auto-derivation eliminates busywork while keeping the name accessible on the instance struct for downstream reference (e.g., in comprehensions that need `inst.metadata.name`).

## Scenarios

### Scenario 1: Observability Stack

A platform team bundles Grafana Operator, Prometheus Operator, and a log collection stack into a ready-to-use observability package. Config is wired explicitly from the bundle-level `#config` into each module instance via `values`.

```cue
// The C alias captures bundle #config at package scope for safe reference inside #instances.
C=#config: {
    storageClass:     string | *"standard"
    retention:        string | *"30d"
    prometheusUrl:    string | *"http://prometheus-server.monitoring:9090"
    logStoreEndpoint: string | *"http://loki.logging:3100"
    domain?:          string
}

#instances: {
    "grafana-operator": {
        module:             grafanaOperatorModule
        metadata: namespace: "monitoring"
        values: {
            datasources: prometheus: url: C.prometheusUrl
        }
    }
    "prometheus-operator": {
        module:             prometheusOperatorModule
        metadata: namespace: "monitoring"
        values: {
            storage: storageClass: C.storageClass
            retention:             C.retention
        }
    }
    "log-collector": {
        module:             logCollectorModule
        metadata: namespace: "logging"
        values: {
            outputEndpoint: C.logStoreEndpoint
        }
    }
}

#policies: {
    "observability-network": network.#SharedNetwork & {
        appliesTo: matchLabels: {
            "bundle.opmodel.dev/name": "observability-stack"
        }
        spec: sharedNetwork: {}
    }
}

debugValues: {
    storageClass:     "standard"
    retention:        "7d"
    prometheusUrl:    "http://prometheus-server.monitoring:9090"
    logStoreEndpoint: "http://loki.logging:3100"
}
```

**BundleRelease:**

```cue
obsRelease: #BundleRelease & {
    metadata: name: "obs-prod"
    #bundle: observabilityStack
    values: {
        storageClass: "gp3"
        retention:    "90d"
        domain:       "monitoring.example.com"
    }
}
```

**Output:**

```text
releases:
  grafana-operator:     #ModuleRelease { namespace: "monitoring", name: "obs-prod-grafana-operator" }
  prometheus-operator:  #ModuleRelease { namespace: "monitoring", name: "obs-prod-prometheus-operator" }
  log-collector:        #ModuleRelease { namespace: "logging",    name: "obs-prod-log-collector" }
```

### Scenario 2: Dynamic Multi-Instance (For-Loop)

A game hosting company deploys N Minecraft servers from a single module template. CUE comprehensions in `#instances` generate one instance per config entry.

```cue
C=#config: {
    servers: [string]: {
        gameMode:   "survival" | "creative" | *"survival"
        maxPlayers: int | *20
        memory:     string | *"2Gi"
    }
}

#instances: {
    for serverName, cfg in C.servers {
        (serverName): {
            module:             minecraftServerModule
            metadata: namespace: "mc-\(serverName)"
            values: {
                gameMode:   cfg.gameMode
                maxPlayers: cfg.maxPlayers
                memory:     cfg.memory
            }
        }
    }
}

debugValues: servers: {
    lobby:    { gameMode: "creative", maxPlayers: 100, memory: "4Gi" }
    survival: { gameMode: "survival", maxPlayers: 50 }
    creative: { gameMode: "creative", maxPlayers: 30 }
}
```

**BundleRelease with debug values produces:**

```text
releases:
  lobby:    #ModuleRelease { namespace: "mc-lobby",    name: "hosting-lobby",    values: { ... } }
  survival: #ModuleRelease { namespace: "mc-survival", name: "hosting-survival", values: { ... } }
  creative: #ModuleRelease { namespace: "mc-creative", name: "hosting-creative", values: { ... } }
```

Three module releases from one module definition. Adding a server is adding a key to `values.servers`.

### Scenario 3: Single Module as Bundle (Minimal)

While standalone `#ModuleRelease` is preferred for single-application deployments, wrapping a single module in a bundle is valid when a unified config surface at the bundle level is needed, or when the module will later grow into a multi-module deployment.

```cue
C=#config: myAppModule.#config  // full passthrough — consumer gets the full module schema

#instances: {
    app: {
        module:             myAppModule
        metadata: namespace: "my-app"
        values:             C  // passthrough pattern
    }
}

debugValues: myAppModule.debugValues
```

**Output:**

```text
releases:
  app: #ModuleRelease { namespace: "my-app", name: "my-release-app", ... }
```

Trivial case. One module, one release. For most single-application deployments, a standalone `#ModuleRelease` is simpler and preferred.

## Module vs Bundle: When to Use Which

### Use a Module When

- Single application or service with one lifecycle
- One team owns all components
- All components share one namespace
- Components have no independent versioning needs
- Dynamic composition is over components (same lifecycle, same release)

### Use a Bundle When

- System of multiple applications that need coordinated deployment
- Cross-module configuration wiring (shared secrets, service URLs)
- Multiple namespaces needed
- Independent module versioning but coordinated distribution
- Dynamic composition over modules (different namespaces, separate releases)
- Platform composition from area-specific bundles
- Curating a "blessed stack" of tested-together modules

### Rule of Thumb

If the components share a lifecycle (always deployed together, same team, same cadence), they belong in one Module. If they have independent lifecycles but need coordination, that is a Bundle.

## Risks / Trade-offs

**[Risk]** Instance name collisions within a bundle if two instances have the same key.
**Mitigation**: CUE unification will fail with a conflict error, surfacing the collision at definition time. Bundle authors MUST ensure unique instance names.

**[Risk]** Bundle-level policies could conflict with module-level policies.
**Mitigation**: CUE unification catches conflicting field values at definition time. Complementary policies (different rule FQNs) merge cleanly.

**[Trade-off]** `#BundleInstance` mini-release wrapper adds verbosity compared to bare `{ module, namespace }`.
**Accepted**: The `metadata` struct and explicit `values` field significantly improve clarity, compile-time safety, and authoring flexibility. The verbosity is justified by the gains in intent clarity and error message quality.

**[Trade-off]** `metadata.namespace!` required on every instance — no default from `module.metadata.defaultNamespace`.
**Accepted**: Making namespace required at the bundle authoring level is an explicit decision rather than a silent default. Bundle authors know their composition context. Consumer-level override is deferred.

## Deferred Work

### Consumer Namespace Override on BundleRelease

How the end-user overrides bundle-author namespace choices at deploy time. Requires further research into whether this belongs in `values`, a dedicated override map, or a separate mechanism.

### Instance Labels and Annotations Propagation

`#BundleInstance.metadata.labels` and `annotations` fields exist in the schema but are not yet wired into the `#BundleRelease` comprehension or the downstream `#ModuleRelease` metadata merge. Propagation semantics (merge order with module labels) need separate design.

### Policy Scope for Cross-Bundle Compositions

When a bundle is deployed alongside other bundles (e.g., a platform operator deploys observability + databases separately), how bundle-level policies interact with policies from other deployments. Needs separate design.
