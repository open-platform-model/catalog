# RFC-0002: Custom Resources

| Field        | Value                              |
|--------------|------------------------------------|
| **Status**   | Draft                              |
| **Created**  | 2026-03-02                         |
| **Authors**  | OPM Contributors                   |

## Summary

Introduce `#CustomResource` — a new core definition type that allows module authors to define their own resource types with embedded, provider-keyed transformers. Custom resources participate in the component model identically to built-in resources (schema in `spec`, transformer output per provider) but are self-contained: the author defines both the input schema and the output transformation.

This is an explicit escape hatch. Module authors use it to model things OPM doesn't cover yet (Flux resources, Crossplane claims, operator CRs, etc.) without waiting for the catalog to add first-class support. Usage should be sparing — custom resources bypass OPM's portability and intent-over-implementation principles by design.

Custom resources register on a dedicated `#customResources` map on `#Component`, separate from built-in `#resources`. They cannot participate in traits or blueprints. Provider targeting uses simple name keys (e.g., `"kubernetes"`) matched against `#Provider.metadata.name`.

## Motivation

### Current State

OPM provides a fixed set of built-in resources: Container, ConfigMaps, Secrets, Volumes, and CRDs. Each follows a well-established pattern:

```text
Schema (#ContainerSchema)
  +---> Resource (#ContainerResource)     -- metadata + #spec + #defaults
         +---> Mixin (#Container)         -- wires into #Component.#resources
                +---> Transformer matches -- by FQN in requiredResources + labels
                       +---> output       -- validated against K8s schemas
```

Adding a new resource requires changes to the catalog itself: schema in `v0/schemas/`, resource definition in `v0/resources/`, transformer in `v0/providers/`, and registration in the provider. This is intentional — it ensures quality, consistency, and portability. But it creates a gap:

**Module authors cannot model resources that OPM hasn't added yet.**

### The Gap

The `add-crds-resource` change solved half the problem: modules can now deploy CRD *definitions* to a cluster. But creating *instances* of custom types (a `GitRepository` CR, a `Grafana` CR, a `Cluster` claim) is not possible. The design explicitly deferred this as a "separate future capability."

Beyond CRD instances, there are entire categories of resources that may never belong in the core catalog but are common in real deployments:

```text
+-------------------------------------------------------------------+
|  Things module authors want to deploy today                        |
|                                                                    |
|  Flux:        GitRepository, HelmRelease, Kustomization           |
|  Crossplane:  Claim, CompositeResource                            |
|  ArgoCD:      Application, ApplicationSet                         |
|  Operators:   Grafana, PostgresCluster, Certificate               |
|  Cloud-native: ExternalSecret, SealedSecret                       |
|                                                                    |
|  None of these have OPM resource definitions.                      |
|  All of them are common in production Kubernetes deployments.      |
+-------------------------------------------------------------------+
```

### Why an Escape Hatch

OPM's principles (portability, declarative intent, composability) are valuable precisely because they constrain the model. Custom resources deliberately loosen those constraints for a specific scope. The design makes this trade-off explicit:

1. **Separate map** (`#customResources` vs `#resources`) — visually distinct in code
2. **Separate type** (`kind: "CustomResource"` vs `kind: "Resource"`) — structurally distinct
3. **No trait composition** — custom resources are standalone, they don't participate in the trait system
4. **No blueprint composition** — custom resources cannot be composed into blueprints
5. **Author-owned output** — the catalog does not validate transformer output; the author is responsible

This is the right trade-off: it unblocks real-world usage while keeping the principled path (built-in resources) as the default.

## Prior Art

### Helm: Raw Resources

Helm has no formal extension mechanism. Users work around this with raw YAML templates or catch-all charts that accept arbitrary manifests. This works but has no schema validation, no composition model, and no separation of concerns.

### Timoni: CUE Flexibility

Timoni modules are plain CUE — any Kubernetes resource can be emitted by adding it to the `objects` list. There is no distinction between "built-in" and "custom" resources. This is maximally flexible but provides no guardrails or visibility into what a module deploys.

### KubeVela: ComponentDefinition

KubeVela allows platform teams to register new component types via `ComponentDefinition` CRDs. These define a schema (parameters) and a CUE template that renders Kubernetes resources. This is the closest analog to what OPM's `#CustomResource` proposes, but operates at the platform level (CRDs in the cluster) rather than the module level (CUE definitions in code).

### Comparison

```text
+---------------------+---------------+---------------+------------------+
|                     | Helm          | KubeVela      | OPM (proposed)   |
+---------------------+---------------+---------------+------------------+
| Extension mechanism | Raw YAML      | CRD-based     | CUE definition   |
| Schema validation   | [ ]           | [x] (CUE)     | [x] (CUE)       |
| Scope               | Chart-level   | Platform-level| Module-level     |
| Provider targeting  | [ ] (K8s only)| [ ] (K8s only)| [x] (per-provider|
| Composition model   | [ ]           | [x] (traits)  | [ ] (standalone) |
| Visible as escape   | [ ]           | [ ]           | [x] (by design)  |
+---------------------+---------------+---------------+------------------+
```

## Design

### `#CustomResource` Definition

A new CUE definition in `v0/core/custom_resource.cue`:

```cue
package core

import "strings"

// #CustomResource: A module-author-defined resource with embedded transformers.
// Escape hatch for modeling things OPM doesn't cover yet.
// Usage should be sparing — prefer built-in resources when available.
//
// Custom resources:
//   - Define their own input schema (#spec)
//   - Carry their own transformers per provider (#providers)
//   - Register on #Component.#customResources (separate from #resources)
//   - Cannot participate in traits or blueprints
//   - Author is responsible for output correctness
#CustomResource: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "CustomResource"

    metadata: {
        apiVersion!:  #APIVersionType
        name!:        #NameType
        _definitionName: (#KebabToPascal & {"in": name}).out
        fqn: #FQNType & "\(apiVersion)#\(_definitionName)"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Input schema — same auto-keying convention as #Resource and #Trait.
    // The field name in #spec is derived from metadata.name:
    //   name: "flux-git-repository" -> #spec: fluxGitRepository: _
    #spec!: (strings.ToCamel(metadata._definitionName)): _

    // Optional defaults for the schema
    #defaults?: _

    // Provider-keyed transformers. Each key is a simple provider name
    // (e.g., "kubernetes") matched against #Provider.metadata.name.
    // At least one provider must be defined.
    #providers!: {
        [providerName=string]: {
            #transform: {
                // Injected by the rendering pipeline:
                #component: _                  // The full component
                #context:   #TransformerContext // Release/module/env metadata

                // Author-defined output. Open struct — no catalog validation.
                // The author MAY import and validate against external schemas
                // (e.g., K8s CRD schemas) but is not required to.
                output: {...}
            }
        }
        // Constraint: at least one provider must be defined
        [string]: _
    }
}

#CustomResourceMap: [string]: _
```

**Key structural rules:**

| Property | Rule |
|----------|------|
| `metadata.fqn` | Auto-computed: `apiVersion + "#" + PascalCase(name)` |
| `#spec` field name | Auto-derived: `ToCamel(PascalCase(name))` |
| `#providers` keys | Simple name strings matching `#Provider.metadata.name` |
| `#providers` | Required, at least one provider must be defined |
| `output` | Open struct (`{...}`), author-owned validation |
| Traits | Not supported — `appliesTo` is absent |
| Blueprints | Not composable into `#Blueprint.composedResources` |

### Updated `#Component`

The component gains an optional `#customResources` map:

```cue
#Component: {
    // ... existing fields unchanged ...

    #resources:        #ResourceMap
    #customResources?: #CustomResourceMap    // NEW
    #traits?:          #TraitMap
    #blueprints?:      #BlueprintMap

    // _allFields merges from all four maps
    _allFields: {
        for _, resource in #resources {
            for k, v in resource.#spec { (k): v }
        }
        if #customResources != _|_ {                          // NEW
            for _, cr in #customResources {                    // NEW
                for k, v in cr.#spec { (k): v }               // NEW
            }                                                  // NEW
        }                                                      // NEW
        if #traits != _|_ {
            for _, trait in #traits {
                for k, v in trait.#spec { (k): v }
            }
        }
        if #blueprints != _|_ {
            for _, blueprint in #blueprints {
                for k, v in blueprint.#spec { (k): v }
            }
        }
    }

    spec: close({ _allFields })
}
```

Custom resource spec fields are merged into the closed `spec` alongside built-in resources, traits, and blueprints. CUE catches field name conflicts at compile time.

### Rendering Pipeline

The `#MatchTransformers` engine gains a second pass for custom resource transformers:

```text
+-------------------------------------------------------------------+
|  RENDERING PIPELINE (two passes)                                    |
|                                                                     |
|  Pass 1 (existing): Provider-owned transformers                     |
|                                                                     |
|    For each transformer in provider.transformers:                   |
|      For each component in module.components:                       |
|        If #Matches(transformer, component):                         |
|          Collect { transformer, component } -> output               |
|                                                                     |
|    Produces: Deployment, Service, ConfigMap, etc.                    |
|                                                                     |
|  Pass 2 (new): Custom resource transformers                         |
|                                                                     |
|    For each component in module.components:                         |
|      If component.#customResources exists:                          |
|        For each customResource in #customResources:                 |
|          If customResource.#providers[provider.metadata.name]:      |
|            Extract #transform, run against component               |
|            Collect { transform, component, customResource } -> out  |
|                                                                     |
|    Produces: GitRepository, Grafana, Certificate, etc.              |
|                                                                     |
|  Both passes produce the same output shape: rendered manifests.     |
+-------------------------------------------------------------------+
```

Updated `#MatchTransformers` (conceptual):

```cue
#MatchTransformers: {
    provider: #Provider
    module:   #ModuleRelease
    out: {
        // Pass 1: provider-owned transformers (unchanged)
        for tID, t in provider.transformers {
            let matches = [
                for _, c in module.components
                if (#Matches & {transformer: t, component: c}).result { c }
            ]
            if len(matches) > 0 {
                (tID): { transformer: t, components: matches }
            }
        }

        // Pass 2: custom resource transformers
        for cID, c in module.components {
            if c.#customResources != _|_ {
                for crFQN, cr in c.#customResources {
                    if cr.#providers[provider.metadata.name] != _|_ {
                        "\(crFQN):\(cID)": {
                            customResource: cr
                            transform:      cr.#providers[provider.metadata.name].#transform
                            component:      c
                        }
                    }
                }
            }
        }
    }
}
```

### Provider Name Matching

Custom resource `#providers` keys are simple name strings matched against `#Provider.metadata.name`:

```text
Custom Resource:                    Provider:
  #providers:                         metadata:
    kubernetes: { ... }     <--->       name: "kubernetes"

Match condition:
  cr.#providers[provider.metadata.name] != _|_
```

This avoids requiring module authors to know or import provider FQNs. The name is sufficient because providers are top-level, non-overlapping definitions.

### Component Mixin Pattern

Custom resources follow the same mixin pattern as built-in resources, using `#customResources` instead of `#resources`:

```cue
// Definition
#FluxGitRepoCustomResource: core.#CustomResource & {
    metadata: {
        apiVersion: "example.com/flux@v0"
        name:       "flux-git-repository"
        description: "A Flux GitRepository source"
    }

    #spec: fluxGitRepository: #FluxGitRepoSchema
    #defaults: { interval: "5m" }

    #providers: kubernetes: #transform: {
        #component: _
        #context:   core.#TransformerContext

        _cr: #component.spec.fluxGitRepository

        output: {
            apiVersion: "source.toolkit.fluxcd.io/v1"
            kind:       "GitRepository"
            metadata: {
                name:      #context.#componentMetadata.name
                namespace: #context.namespace
                labels:    #context.labels
            }
            spec: {
                url:      _cr.url
                interval: _cr.interval
                if _cr.ref != _|_ {
                    ref: _cr.ref
                }
                if _cr.secretRef != _|_ {
                    secretRef: _cr.secretRef
                }
            }
        }
    }
}

// Mixin
#FluxGitRepo: core.#Component & {
    #customResources: {
        (#FluxGitRepoCustomResource.metadata.fqn): #FluxGitRepoCustomResource
    }
}
```

### Usage in a Module

```cue
import (
    "opmodel.dev/core@v0"
    workload "opmodel.dev/core@v0:blueprints_workload"
    flux     "example.com/flux@v0"   // module author's package
)

#AppModule: core.#Module & {
    metadata: {
        apiVersion: "example.com/app@v0"
        name:       "my-app"
        version:    "1.0.0"
    }

    #config: {
        repoUrl!:  string
        branch:    *"main" | string
        interval:  *"5m" | string
    }

    #components: {
        app: core.#Component & {
            workload.#StatelessWorkload
            flux.#FluxGitRepo

            spec: {
                statelessWorkload: {
                    container: {
                        name:  "app"
                        image: "myapp:latest"
                    }
                }
                fluxGitRepository: {
                    url:      #config.repoUrl
                    interval: #config.interval
                    ref: branch: #config.branch
                }
            }
        }
    }
}
```

From the component author's perspective, custom resources are indistinguishable from built-in resources in usage. The distinction is structural (separate map) and visible in code review.

### Label and Annotation Inheritance

Custom resource metadata labels and annotations are inherited by the component, following the same pattern as built-in resources:

```cue
// In #Component.metadata:
labels: #LabelsAnnotationsType & {
    for _, resource in #resources { /* existing */ }
    if #customResources != _|_ {                           // NEW
        for _, cr in #customResources {
            if cr.metadata.labels != _|_ {
                for lk, lv in cr.metadata.labels { (lk): lv }
            }
        }
    }
    // ... traits, blueprints unchanged
}
```

### Constraints

The following are intentional constraints, not future work:

1. **No trait composition.** Custom resources do not have an `appliesTo` field. Existing traits cannot target custom resources. Custom resources cannot define their own traits.

2. **No blueprint composition.** `#Blueprint.composedResources` accepts `[...#Resource]`, not `[...#CustomResource]`. Custom resources cannot be bundled into blueprints.

3. **No cross-custom-resource references.** Custom resources are standalone. One custom resource cannot reference another's spec fields. If composition is needed, the author should build a single custom resource that handles both.

4. **No output validation by the catalog.** The `output: {...}` field is an open struct. The catalog does not import or validate against external CRD schemas. Authors MAY self-validate by importing schemas (e.g., `fluxv1.#GitRepository & { ... }`).

## Examples

### Example: Flux GitRepository + HelmRelease

A module that manages Flux resources for GitOps deployment:

```cue
// Schema definitions
#FluxGitRepoSchema: {
    url!:      string
    ref?: {
        branch?: string
        tag?:    string
        semver?: string
    }
    interval!: string & =~"^[0-9]+(s|m|h)$"
    secretRef?: name: string
}

#FluxHelmReleaseSchema: {
    chart!: {
        name!:    string
        version?: string
    }
    sourceRef!: {
        kind: *"GitRepository" | "HelmRepository"
        name: string
    }
    interval!: string & =~"^[0-9]+(s|m|h)$"
    values?: {...}
}

// Custom resource: Flux GitRepository
#FluxGitRepoCustomResource: core.#CustomResource & {
    metadata: {
        apiVersion:  "example.com/flux@v0"
        name:        "flux-git-repository"
        description: "A Flux GitRepository source definition"
    }
    #spec: fluxGitRepository: #FluxGitRepoSchema
    #defaults: { interval: "5m" }

    #providers: kubernetes: #transform: {
        #component: _
        #context: core.#TransformerContext
        _cr: #component.spec.fluxGitRepository
        output: {
            apiVersion: "source.toolkit.fluxcd.io/v1"
            kind:       "GitRepository"
            metadata: {
                name:      #context.#componentMetadata.name
                namespace: #context.namespace
                labels:    #context.labels
            }
            spec: {
                url:      _cr.url
                interval: _cr.interval
                if _cr.ref != _|_ { ref: _cr.ref }
                if _cr.secretRef != _|_ { secretRef: _cr.secretRef }
            }
        }
    }
}

// Custom resource: Flux HelmRelease
#FluxHelmReleaseCustomResource: core.#CustomResource & {
    metadata: {
        apiVersion:  "example.com/flux@v0"
        name:        "flux-helm-release"
        description: "A Flux HelmRelease for deploying Helm charts"
    }
    #spec: fluxHelmRelease: #FluxHelmReleaseSchema
    #defaults: { interval: "10m" }

    #providers: kubernetes: #transform: {
        #component: _
        #context: core.#TransformerContext
        _cr: #component.spec.fluxHelmRelease
        output: {
            apiVersion: "helm.toolkit.fluxcd.io/v2"
            kind:       "HelmRelease"
            metadata: {
                name:      #context.#componentMetadata.name
                namespace: #context.namespace
                labels:    #context.labels
            }
            spec: {
                chart: spec: {
                    chart:   _cr.chart.name
                    if _cr.chart.version != _|_ { version: _cr.chart.version }
                    sourceRef: _cr.sourceRef
                }
                interval: _cr.interval
                if _cr.values != _|_ { values: _cr.values }
            }
        }
    }
}

// Mixins
#FluxGitRepo: core.#Component & {
    #customResources: {
        (#FluxGitRepoCustomResource.metadata.fqn): #FluxGitRepoCustomResource
    }
}

#FluxHelmRelease: core.#Component & {
    #customResources: {
        (#FluxHelmReleaseCustomResource.metadata.fqn): #FluxHelmReleaseCustomResource
    }
}
```

### Example: Multi-Provider Custom Resource

A custom resource that targets both Kubernetes and a hypothetical cloud provider:

```cue
#ManagedDatabaseCustomResource: core.#CustomResource & {
    metadata: {
        apiVersion: "example.com/data@v0"
        name:       "managed-database"
        description: "A managed database provisioned via the target platform"
    }
    #spec: managedDatabase: {
        engine!:  "postgres" | "mysql"
        version!: string
        storage!: string & =~"^[0-9]+(Gi|Ti)$"
        ha:       *false | bool
    }

    #providers: {
        // Kubernetes: emit a CloudNativePG Cluster CR
        kubernetes: #transform: {
            #component: _
            #context: core.#TransformerContext
            _db: #component.spec.managedDatabase
            output: {
                apiVersion: "postgresql.cnpg.io/v1"
                kind:       "Cluster"
                metadata: {
                    name:      #context.#componentMetadata.name
                    namespace: #context.namespace
                    labels:    #context.labels
                }
                spec: {
                    instances:  1
                    if _db.ha { instances: 3 }
                    postgresql: parameters: {}
                    storage: size: _db.storage
                }
            }
        }

        // Hypothetical cloud provider
        "cloud-provider": #transform: {
            #component: _
            #context: core.#TransformerContext
            _db: #component.spec.managedDatabase
            output: {
                type:    "managed-database"
                engine:  _db.engine
                version: _db.version
                storage: _db.storage
                ha:      _db.ha
                region:  "us-east-1"
            }
        }
    }
}
```

This demonstrates the multi-provider value: the same `managedDatabase` spec renders to a CloudNativePG `Cluster` CR on Kubernetes, or a cloud-native database API call on a different provider.

## Migration Path

When a custom resource becomes common enough, the catalog can promote it to a built-in resource:

```text
+-------------------------------------------------------------------+
|  PROMOTION PATH                                                     |
|                                                                     |
|  1. Module author creates #FluxGitRepoCustomResource               |
|     -> Lives in their module, #customResources map                  |
|                                                                     |
|  2. Pattern proves useful across multiple modules                   |
|     -> Community recognizes the need                                |
|                                                                     |
|  3. Catalog adds #FluxGitRepoResource (built-in)                   |
|     -> Schema in v0/schemas/, resource in v0/resources/             |
|     -> Transformer in v0/providers/kubernetes/transformers/         |
|     -> Registered in provider.cue                                   |
|                                                                     |
|  4. Module authors migrate:                                         |
|     - Replace #customResources entry with #resources entry          |
|     - Delete custom resource definition                             |
|     - Use built-in mixin instead                                    |
|                                                                     |
|  The spec field name stays the same (auto-derived from name),       |
|  so component.spec doesn't change if the name matches.              |
+-------------------------------------------------------------------+
```

## Deferred Work

### Custom Traits

Custom resources currently cannot define or participate in traits. If a need emerges for custom behavioral modifiers (e.g., "add Flux annotations to all custom resources"), this would be a separate RFC.

### Custom Resource Registries

If custom resources proliferate, a registry or package convention for sharing them across modules may be needed. Deferred until usage patterns emerge.

### Output Schema Validation

The catalog currently does not validate custom resource transformer output. If common patterns emerge (e.g., "all Kubernetes custom resources must have apiVersion, kind, metadata"), optional output schema validation could be added.

### List Output Support

Built-in resources support map-based specs that produce multiple outputs (flagged with `"transformer.opmodel.dev/list-output": true`). Custom resources could support the same pattern. Deferred until a concrete use case appears.
