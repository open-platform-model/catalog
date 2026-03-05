# RFC-0003: Bundle System

| Field        | Value                              |
|--------------|------------------------------------|
| **Status**   | Draft                              |
| **Created**  | 2026-03-02                         |
| **Authors**  | OPM Contributors                   |

## Summary

Redesign `#Bundle` as OPM's composition and coordination layer for complex, multi-module deployments. Bundles group modules and other bundles into a recursive, composable structure with per-instance namespace control, cross-module config wiring, bundle-level policies, and CUE comprehension-based dynamic composition. Standalone `#ModuleRelease` remains the primary path for single-application deployments.

Introduce `#BundleRelease` which resolves a bundle (including all nested bundles) into a flat map of `#ModuleRelease` instances — feeding directly into the existing provider/transformer pipeline with zero changes downstream.

The key design insight: since OPM modules are CUE structural references (not opaque artifacts), bundle authors can unify with module internals, reference their fields, and CUE validates everything at definition time. This gives OPM bundles significantly more power than Timoni or Helm umbrella charts, where module/chart references are external and opaque.

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

- The `{module, namespace, values}` instance pattern is adopted by OPM as `#BundleInstance`
- OPM diverges by using CUE structural references (not opaque OCI URLs), enabling cross-module field references and compile-time validation
- OPM adds centralized `#config` at the bundle level for the consumer-facing schema, with explicit wiring to module configs
- OPM adds recursive nesting, policies, and CUE comprehension-based dynamic composition

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
│ Nesting              │ [ ]              │ [ ] (ad hoc)     │ [x] Recursive    │
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
│  #BundleInstance   Per-module entry: {module, namespace}             │
│  #Bundle           Recursive container: instances + bundles + config │
│  #BundleRelease    Concrete deployment: flattens to ModuleReleases  │
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

Each entry within a bundle carries a reference to either a module or a nested bundle, plus an optional namespace override:

```cue
#BundleInstance: {
    instance!:  #Module | #Bundle
    namespace?: string
}
```

| Field       | Required | Purpose                        |
|-------------|----------|--------------------------------|
| `instance`  | Yes      | The module or bundle to include |
| `namespace` | No       | Target namespace override (meaningful for `#Module`, ignored for `#Bundle`) |

The `instance` field accepts either a `#Module` or a `#Bundle`, discriminated by the `kind` field (`"Module"` vs `"Bundle"`). CUE validates the disjunction at definition time.

**Namespace behavior:**
- When `instance` is a `#Module`: `namespace` overrides `module.metadata.defaultNamespace`. If omitted, the default namespace is resolved during flattening.
- When `instance` is a `#Bundle`: `namespace` is ignored — the nested bundle controls its own namespace assignments internally.

**Namespace cascade**: Module author sets `metadata.defaultNamespace` as the suggestion. Bundle author overrides via `#BundleInstance.namespace`. Consumer overrides at deploy time (mechanism deferred — see [Deferred Work](#deferred-work)).

The field is named `#instances` to signal these are instantiations. The same module MAY appear multiple times in the same bundle under different instance names (e.g., the Minecraft multi-server pattern). A bundle MAY also appear multiple times if needed.

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

    // Instances in this bundle — each is a module or a nested bundle
    #instances!: [Name=string]: #BundleInstance

    // Bundle-level config schema — consumer-facing
    // Bundle author wires this to module configs via CUE unification
    #config!: _

    // Bundle-level policies — cross-module governance
    #policies?: [string]: #Policy

    // Debug/test values
    debugValues: _
}
```

**Key properties:**

- **Unified**: A single `#instances` field holds both module and bundle entries, discriminated by `instance.kind`
- **Recursive**: Instances with `instance: #Bundle` enable platform-of-bundles composition
- **Required**: `#instances` is required — a bundle must contain at least one instance
- **Meta-bundles allowed**: A bundle where all instances are other bundles (no direct modules) is valid
- **Namespace ignored for bundles**: When an instance is a `#Bundle`, the `namespace` field is ignored — the nested bundle controls its own namespace assignments internally (see [D5: Nested Bundle Namespace](#d5-nested-bundle-namespace))

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

    // Flattened output: ALL nested bundles resolved to module releases
    // Keys are kebab-case path-qualified (e.g., "observability-grafana")
    releases: [string]: #ModuleRelease

    // Bundle-level policies (resolved)
    policies?: [string]: #Policy
}
```

**Flattening rules:**

1. Direct instances produce keys equal to their instance name
2. Nested bundle instances are prefixed with the bundle name, joined by hyphens
3. All nesting levels are resolved recursively — the final output is always a flat map
4. CUE unification catches key collisions at definition time

```text
┌──────────────────────────────────────────────────────────────────────────┐
│  FLATTENING                                                              │
│                                                                          │
│  Input:                                                                  │
│    platform-bundle                                                       │
│    └── #instances:                                                       │
│          cert-manager:  { instance: certMgrModule, ns: "cert-manager" }  │
│          ingress:       { instance: ingressModule, ns: "ingress" }       │
│          observability: { instance: obsBundle }          ◄── #Bundle     │
│              └── #instances:                                             │
│                    grafana:    { instance: grafanaModule, ns: "mon" }    │
│                    prometheus: { instance: promModule,    ns: "mon" }    │
│                                                                          │
│  Output (BundleRelease.releases):                                        │
│    cert-manager:              ModuleRelease { ns: "cert-manager" }       │
│    ingress:                   ModuleRelease { ns: "ingress" }            │
│    observability-grafana:     ModuleRelease { ns: "monitoring" }         │
│    observability-prometheus:  ModuleRelease { ns: "monitoring" }         │
│                                                                          │
│  Every key is a valid #NameType (kebab-case, max 63 chars).             │
└──────────────────────────────────────────────────────────────────────────┘
```

### Config Wiring

Bundle authors wire `#config` to module configs explicitly using CUE unification. There is no automatic config cascading.

```cue
observabilityStack: #Bundle & {
    #config: {
        storageClass: string | *"standard"
        retention:    string | *"30d"
        domain?:      string
    }

    #instances: {
        prometheus: {
            instance: prometheusModule & {
                #config: {
                    storage: storageClass: #config.storageClass
                    retention:             #config.retention
                }
            }
            namespace: "monitoring"
        }
        grafana: {
            instance: grafanaModule & {
                #config: {
                    datasources: prometheus: url: "http://prometheus-server.monitoring:9090"
                    if #config.domain != _|_ {
                        ingress: host: "grafana.\(#config.domain)"
                    }
                }
            }
            namespace: "monitoring"
        }
    }
}
```

Each nesting level wires independently. A platform bundle maps platform config to child bundle configs. The child bundle maps its config to module configs. No hidden magic.

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

CUE comprehensions in `#instances` enable dynamic module instantiation from config:

```cue
minecraftHosting: #Bundle & {
    #config: {
        servers: [string]: {
            gameMode:   "survival" | "creative" | *"survival"
            maxPlayers: int | *20
            memory:     string | *"2Gi"
        }
    }

    #instances: {
        for name, cfg in #config.servers {
            (name): {
                instance: minecraftServerModule & {
                    #config: {
                        gameMode:   cfg.gameMode
                        maxPlayers: cfg.maxPlayers
                        memory:     cfg.memory
                    }
                }
                namespace: "mc-\(name)"
            }
        }
    }

    debugValues: servers: {
        lobby:    { gameMode: "creative", maxPlayers: 100, memory: "4Gi" }
        survival: { gameMode: "survival", maxPlayers: 50 }
        creative: { gameMode: "creative", maxPlayers: 30 }
    }
}
```

This generates three module releases from one module definition. Each instance gets its own namespace, its own config, and its own `#ModuleRelease` in the flattened output.

Note: similar dynamic composition is possible within a module using for-loops over `#components`. The difference:

| | Module for-loop (components) | Bundle for-loop (instances) |
|---|---|---|
| Unit generated | Components | Modules |
| Namespace | Shared (one namespace) | Independent (per-instance) |
| Lifecycle | One release, one lifecycle | Separate releases |
| Use case | N workers in one app | N independent instances |

### Dependencies

CUE imports and structural references naturally encode the dependency graph between modules and bundles. When a bundle author writes:

```cue
import core "opmodel.dev/bundles/core@v1"

authBundle: #Bundle & {
    #instances: {
        "core": {
            instance: core.coreBundle  // CUE import = implicit dependency
        }
        dex: {
            instance: dexModule & {
                // CUE reference to core's instance = implicit dependency
                #config: ingressClass: #instances.core.instance.#instances.ingress.instance.metadata.name
            }
            namespace: "auth"
        }
    }
}
```

The CUE import of `core` makes the dependency explicit at the language level. No separate `dependsOn` metadata is needed for structural dependencies. The CLI/orchestrator can derive the deployment graph from CUE's module dependency tree.

## Decisions

### D1: Bundle Structure — Flat vs Recursive

**Context**: Bundles need to support both simple module groupings (observability stack) and large platform compositions (core + auth + observability + databases + AI bundles).

**Options considered:**

1. **Flat** — Bundle contains only Modules. Platform composition is external.
2. **Recursive** — Bundle contains Modules and/or other Bundles.
3. **Flat with external deps** — Bundle contains only Modules but declares `dependsOn` other Bundles by name.

**Decision**: Option 2 — Recursive.

**Rationale**: CUE handles recursive types well. Config cascading is not automatic (each level wires explicitly via CUE unification), so depth does not add hidden complexity. The advanced platform scenario requires formal composition. Typical nesting depth is 2 levels (platform → area → module). CUE imports and structural references naturally encode the dependency graph.

### D2: Entry Type — Bare Reference vs Instance Wrapper

**Context**: Bundles need per-entry metadata (at minimum: namespace for modules). The current `#ModuleMap` is `[string]: #Module` — a bare map with no room for per-instance config.

**Options considered:**
1. **Bare maps** — Keep `#modules: [string]: #Module` and `#bundles: [string]: #Bundle`. Namespace lives only on `#ModuleRelease`.
2. **Instance wrapper** — `#instances: [string]: { instance: #Module | #Bundle, namespace? }`.

**Decision**: Option 2 — Instance wrapper (`#BundleInstance`).

**Rationale**: Inspired by Timoni bundles. The namespace gap between `#Bundle` (authoring) and `#ModuleRelease` (deployment) is a real structural problem. The wrapper solves it and is extensible for future per-instance settings. The `instance` field uses a `#Module | #Bundle` disjunction, giving a single unified `#instances` map. Named `#instances` to signal instantiation semantics — the same module or bundle can appear multiple times.

### D3: BundleRelease Output — Nested vs Flattened

**Context**: `#BundleRelease` resolves a bundle with concrete values. The output could preserve nesting or flatten everything.

**Options considered:**

1. **Nested** — Output preserves bundle structure with nested `#BundleRelease` entries.
2. **Flattened** — Output is `[string]: #ModuleRelease`. All nesting resolved.

**Decision**: Option 2 — Flattened.

**Rationale**: The provider/transformer pipeline operates on `#ModuleRelease`. Preserving nesting would require every downstream consumer to handle recursion. Flattening at the bundle level keeps the consumer interface simple. Kebab-case path-qualified keys avoid collisions.

### D4: Namespace Assignment Cascade

**Context**: Three actors need namespace control: module author (default), bundle author (override), consumer (final override at deploy time).

**Decision**: Three-layer cascade via `#BundleInstance`:

1. Module author sets `metadata.defaultNamespace` (suggestion)
2. Bundle author overrides via `#BundleInstance.namespace` (composition)
3. Consumer overrides at deploy time (mechanism deferred)

**Rationale**: Matches the ownership model. Module author suggests, bundle author overrides for their composition, consumer has final say.

### D5: Nested Bundle Namespace — Ignored

**Context**: When bundle A includes bundle B as an instance, should the `namespace` field on that instance override the namespaces of modules inside bundle B?

**Decision**: No. When `instance` is a `#Bundle`, the `namespace` field on `#BundleInstance` is ignored. The nested bundle controls its own namespace assignments internally.

**Rationale**: If bundle A overrides namespaces inside bundle B, it breaks bundle B's internal assumptions (service discovery, network policies, inter-module references). The bundle author of B designed their namespace layout intentionally. Bundle A trusts bundle B's choices. If different namespaces are needed, the consumer should fork or configure bundle B directly.

### D6: Bundle-Level Policies

**Context**: Modules define `#policies` for intra-module governance. Bundles need cross-module governance.

**Decision**: Bundles get `#policies?: [string]: #Policy` using the existing `#Policy` type.

**Rationale**: `appliesTo.matchLabels` naturally works across modules — it matches any component whose labels satisfy the selector. No changes to `#Policy` needed.

### D7: Config Pattern — Explicit Wiring

**Context**: Bundle `#config` defines the consumer-facing schema. Module `#config` defines each module's schema. How do values flow?

**Decision**: Explicit wiring by the bundle author using CUE unification.

**Rationale**: Each level maps its `#config` fields to child configs explicitly. This is just CUE — no new mechanism. No hidden cascading. A passthrough mechanism for bundles that just group modules without custom config is deferred.

### D8: Release Key Format

**Context**: Flattened `#BundleRelease.releases` needs unique keys when the same instance name could appear in different nested bundles.

**Decision**: Kebab-case path-qualified keys. Nested instances are prefixed with their parent bundle name, joined by hyphens.

**Examples:**

- Direct instance `grafana` → key: `grafana`
- Instance `grafana` inside bundle `observability` → key: `observability-grafana`
- Instance `agent` inside bundle `logging` inside bundle `observability` → key: `observability-logging-agent`

**Rationale**: Consistent with `#NameType` constraints. Produces valid kebab-case identifiers.

### D9: Bundle Positioning — Complex Deployments

**Context**: Should Bundle be positioned as the primary deployment unit for all cases, or scoped to complex multi-module scenarios?

**Decision**: Bundles are the composition and coordination layer for complex deployments. Standalone `#ModuleRelease` remains the primary path for single-application deployments.

**Rationale**: Bundles add value when there is cross-module coordination (shared config, policies, multi-namespace, dynamic composition). For a single application with one module and one namespace, `#ModuleRelease` is simpler and sufficient. Bundles shine for platforms, curated stacks, and multi-instance patterns. The flow depends on complexity: simple apps use `Module Author → Consumer (ModuleRelease)`, complex systems use `Module Author → Bundle Author → Consumer (BundleRelease)`.

### D10: Unified Instance Field

**Context**: Should modules and bundles within a bundle use the same field name or separate fields?

**Options considered:**

1. **Separate fields** — `#instances` for modules, `#bundles` for nested bundles.
2. **Unified field** — Single `#instances` containing both module and bundle entries via `instance!: #Module | #Bundle`.

**Decision**: Option 2 — Unified field.

**Rationale**: A single `#instances` field with `instance!: #Module | #Bundle` provides a simpler mental model: a bundle contains instances, each instance is either a module or another bundle. The `namespace` field is present on all entries but only meaningful for modules (ignored for bundles). CUE's `kind` field discriminates between `#Module` and `#Bundle` at evaluation time. This avoids two parallel maps with different entry types and keeps the API surface minimal.

## Scenarios

### Scenario 1: Observability Stack (Simple Bundle)

A platform team bundles Grafana Operator, Prometheus Operator, and a log collection stack into a ready-to-use observability package.

```cue
observabilityStack: #Bundle & {
    metadata: {
        modulePath: "opmodel.dev/bundles"
        name:       "observability-stack"
        version:    "v1"
    }

    #instances: {
        "grafana-operator": {
            instance: grafanaOperatorModule & {
                #config: {
                    datasources: prometheus: url: #config.prometheusUrl
                }
            }
            namespace: "monitoring"
        }
        "prometheus-operator": {
            instance: prometheusOperatorModule & {
                #config: {
                    storage: storageClass: #config.storageClass
                    retention:             #config.retention
                }
            }
            namespace: "monitoring"
        }
        "log-collector": {
            instance: logCollectorModule & {
                #config: {
                    outputEndpoint: #config.logStoreEndpoint
                }
            }
            namespace: "logging"
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

    #config: {
        storageClass:     string | *"standard"
        retention:        string | *"30d"
        prometheusUrl:    string | *"http://prometheus-server.monitoring:9090"
        logStoreEndpoint: string | *"http://loki.logging:3100"
        domain?:          string
    }

    debugValues: {
        storageClass:     "standard"
        retention:        "7d"
        prometheusUrl:    "http://prometheus-server.monitoring:9090"
        logStoreEndpoint: "http://loki.logging:3100"
    }
}
```

**BundleRelease:**

```cue
obsRelease: #BundleRelease & {
    metadata: name: "obs-prod"
    #bundle: observabilityStack
    values: {
        storageClass:  "gp3"
        retention:     "90d"
        domain:        "monitoring.example.com"
    }
}
```

**Flattened output:**

```text
releases:
  grafana-operator:     #ModuleRelease { namespace: "monitoring", ... }
  prometheus-operator:  #ModuleRelease { namespace: "monitoring", ... }
  log-collector:        #ModuleRelease { namespace: "logging", ... }
```

### Scenario 2: Platform Composition (Nested Bundles)

A platform team composes an entire platform from area-specific bundles. Core is required; others are optional and can be added later.

```cue
import (
    core "opmodel.dev/bundles/core@v1"
    obs  "opmodel.dev/bundles/observability@v1"
    db   "opmodel.dev/bundles/databases@v1"
)

acmePlatform: #Bundle & {
    metadata: {
        modulePath: "acme.com/platform"
        name:       "acme-platform"
        version:    "v2"
    }

    // All instances are bundles — this is a meta-bundle
    #instances: {
        "core": {
            instance: core.coreBundle & {
                #config: domain: #config.domain
            }
        }
        "observability": {
            instance: obs.observabilityStack & {
                #config: {
                    domain:       #config.domain
                    storageClass: #config.storageClass
                }
            }
        }
        "databases": {
            instance: db.databasesBundle & {
                #config: {
                    storageClass: #config.storageClass
                }
            }
        }
    }

    #config: {
        domain!:       string
        storageClass:  string | *"standard"
        environment:   "dev" | "staging" | "production"
    }

    debugValues: {
        domain:       "dev.acme.internal"
        storageClass: "standard"
        environment:  "dev"
    }
}
```

**Flattened output (assuming core has cert-manager and ingress, obs has grafana/prometheus/logs, db has cnpg/redis):**

```text
releases:
  core-cert-manager:              #ModuleRelease { namespace: "cert-manager" }
  core-ingress:                   #ModuleRelease { namespace: "ingress" }
  observability-grafana-operator: #ModuleRelease { namespace: "monitoring" }
  observability-prometheus:       #ModuleRelease { namespace: "monitoring" }
  observability-log-collector:    #ModuleRelease { namespace: "logging" }
  databases-cnpg-operator:        #ModuleRelease { namespace: "databases" }
  databases-redis-operator:       #ModuleRelease { namespace: "databases" }
```

All nested structure resolved. Seven module releases from one bundle release. Each key is kebab-case path-qualified.

### Scenario 3: Dynamic Multi-Instance (For-Loop)

A game hosting company deploys N Minecraft servers from a single module template.

```cue
minecraftHosting: #Bundle & {
    metadata: {
        modulePath: "gamehosting.com/bundles"
        name:       "minecraft-hosting"
        version:    "v1"
    }

    #instances: {
        for name, cfg in #config.servers {
            (name): {
                instance: minecraftServerModule & {
                    #config: {
                        gameMode:   cfg.gameMode
                        maxPlayers: cfg.maxPlayers
                        memory:     cfg.memory
                    }
                }
                namespace: "mc-\(name)"
            }
        }
    }

    #config: {
        servers: [string]: {
            gameMode:   "survival" | "creative" | *"survival"
            maxPlayers: int | *20
            memory:     string | *"2Gi"
        }
    }

    debugValues: servers: {
        lobby:    { gameMode: "creative", maxPlayers: 100, memory: "4Gi" }
        survival: { gameMode: "survival", maxPlayers: 50 }
        creative: { gameMode: "creative", maxPlayers: 30 }
    }
}
```

**BundleRelease with debug values flattens to:**

```text
releases:
  lobby:    #ModuleRelease { namespace: "mc-lobby",    values: { ... } }
  survival: #ModuleRelease { namespace: "mc-survival", values: { ... } }
  creative: #ModuleRelease { namespace: "mc-creative", values: { ... } }
```

Three module releases from one module definition. Adding a server is adding a key to `values.servers`.

### Scenario 4: Single Module as Bundle (Minimal)

While standalone `#ModuleRelease` is preferred for single-application deployments, wrapping a single module in a bundle is valid when namespace control or a unified config surface is needed at the bundle level.

```cue
myApp: #Bundle & {
    metadata: {
        modulePath: "example.com/bundles"
        name:       "my-app"
        version:    "v1"
    }

    #instances: {
        app: {
            instance:  myAppModule
            namespace: "my-app"
        }
    }

    #config: myAppModule.#config

    debugValues: myAppModule.debugValues
}
```

**Flattened output:**

```text
releases:
  app: #ModuleRelease { namespace: "my-app", ... }
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

**[Risk]** Recursive bundle evaluation could be slow for deeply nested structures.
**Mitigation**: Practical nesting depth is 2-3 levels. CUE handles this well. Document recommended max depth.

**[Risk]** Flattened release key collisions if two nested bundles have instances with identical derived names.
**Mitigation**: CUE unification will fail with a conflict error, surfacing the collision at definition time. Bundle authors MUST ensure unique instance names across their composition.

**[Risk]** Bundle-level policies could conflict with module-level policies.
**Mitigation**: CUE unification catches conflicting field values at definition time. Complementary policies (different rule FQNs) merge cleanly.

**[Trade-off]** `#BundleInstance` wrapper adds verbosity compared to bare `#ModuleMap`.
**Accepted**: The namespace control and extensibility justify the extra structure. Namespace defaults to `module.metadata.defaultNamespace` for the common case.

**[Trade-off]** `namespace` on `#BundleInstance` is ignored when `instance` is a `#Bundle`, limiting flexibility.
**Accepted**: Preserves ownership boundaries. The alternative creates ambiguous semantics and breaks bundle encapsulation.

## Deferred Work

### Consumer Namespace Override on BundleRelease

How the end-user overrides bundle-author namespace choices at deploy time. Requires further research into whether this belongs in `values`, a dedicated override map, or a separate mechanism.

### Passthrough Config Mechanism

An explicit mechanism for bundles that group modules without defining a custom `#config` schema. Would auto-mirror module configs under a namespace key. Needs separate design.

### Policy Scope in Nested Bundles

Whether a parent bundle's policies apply to all nested components or only to direct instances. Needs separate design.

### Removing ModuleRelease / BundleRelease Separation

The current split creates a structural gap where the bundle author (who writes `#Bundle`) cannot fully control deploy-time concerns (which live on Release types). Collapsing them would simplify namespace cascading but requires rethinking the render pipeline, `#TransformerContext`, `autoSecrets`, and all consumer-facing APIs. Major undertaking.
