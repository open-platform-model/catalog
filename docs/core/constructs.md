# OPM Constructs

Constructs are framework types that organize, compose, deploy, render, and verify. They consume [Primitives](primitives.md) but don't define schemas for composition themselves.

See [Definition Types](definition-types.md) for the full taxonomy.

---

## Composition

### Component

A **Component** composes Primitives (Resources, Traits, Blueprints) into a single unit with a unified `spec`. Components are the building blocks of a Module — each component represents at least one deployable piece of the application.

Resources, Traits, and Blueprints each define independent `#spec` schemas. A Component merges all of them into a single flat `spec` via CUE unification. This means conflicting field definitions between attached primitives are caught at definition time — not at deployment.

#### What Component Infers

- "This is one **deployable unit** within the application"
- "This **composes** independently authored primitives into a single spec"
- "This is what **Transformers** target to produce platform-specific output"

#### Component Structure

```cue
#Component: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Component"

    metadata: {
        name!:        string
        labels:       {...}   // Auto-inherited from attached resources, traits
        annotations?: {...}   // Auto-inherited from attached resources, traits
    }

    #resources:  [FQN=string]: #Resource    // Required — at least one
    #traits?:    [FQN=string]: #Trait        // Optional behavioral modifiers
    #blueprints?: [FQN=string]: #Blueprint   // Optional reusable patterns

    spec: close({...})  // Unified from all #resources, #traits, #blueprints specs
}
```

#### Key Relationships

```text
Resources ──┐
Traits ─────┤──unify──▶ Component.spec
Blueprints ─┘

Component.metadata.labels ◀── inherited from attached definitions
Transformer ── matches ──▶ Component (via labels + definition FQNs)
```

Labels flow upward: when a Resource or Trait has labels (e.g., `"core.opmodel.dev/workload-type": "stateless"`), those labels propagate to the Component. Transformers then match components by these inherited labels.

**CUE schema**: [`v0/core/component.cue`](../../v0/core/component.cue)

### Module

A **Module** is the top-level application definition. It groups Components, Policies, a config schema (`#config`), and default values (`values`) into a portable, versionable unit that a Module Author publishes.

Modules enforce a clear separation between the configuration contract (`#config` — constraints only, no defaults) and the default values (`values` — sane defaults that satisfy the contract). This separation enables the delivery flow: Module Authors define the contract and defaults, Platform Operators can refine constraints via CUE unification, and End-users provide concrete values via ModuleRelease.

#### What Module Infers

- "This is the **complete application definition**"
- "This is **versioned and publishable** to a registry"
- "This defines the **configuration contract** consumers must satisfy"

#### Module Structure

```cue
#Module: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Module"

    metadata: {
        apiVersion!:       string  // e.g., "example.com/modules@v0"
        name!:             string  // e.g., "my-app"
        fqn:               string  // Computed: "{apiVersion}#{Name}"
        version!:          string  // SemVer: "1.0.0"
        defaultNamespace?: string
        description?:      string
    }

    #components: [Id=string]: #Component  // The application's deployable pieces
    #policies?:  [Id=string]: #Policy     // Cross-cutting governance

    #config: _  // Value schema — constraints only, NO defaults
    values: _   // Concrete default values for development/testing
}
```

#### Key Relationships

```text
Module Author ──defines──▶ Module (#components, #config, values)
Platform Team ──refines──▶ Module (add policies, tighten constraints via CUE unification)
End-user ──deploys──▶ ModuleRelease (concrete values overriding defaults)
```

#### Module Example

```cue
basicModule: core.#Module & {
    metadata: {
        apiVersion: "opmodel.dev@v0"
        name:       "basic-module"
        version:    "0.1.0"
    }

    #components: {
        web: components.basicComponent & {
            spec: {
                replicas: #config.web.replicas
                container: image: #config.web.image
            }
        }
    }

    #config: {
        web: {
            replicas: int
            image:    string
        }
    }

    values: {
        web: {
            replicas: 1
            image:    "nginx:1.20.0"
        }
    }
}
```

**CUE schema**: [`v0/core/module.cue`](../../v0/core/module.cue)

### Policy

A **Policy** groups [PolicyRules](primitives.md#policyrule) and targets them to a set of Components via label matching or explicit references. Policies enable cross-cutting governance without coupling rules to individual components.

Policy follows the same composition pattern as Component: PolicyRules define independent `#spec` schemas, and Policy merges them into a single `spec` via `_allFields`. Pre-built policies from the `v0/policies/` module can be composed together via CUE unification — a module author can combine network rules and shared networking into a single policy by unifying them.

#### What Policy Infers

- "These **governance rules** apply to this set of components"
- "This is **cross-cutting** — it spans multiple components"
- "This **decouples** governance from component definitions"

#### Policy Structure

```cue
#Policy: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Policy"

    metadata: {
        name!:        string
        labels?:      {...}
        annotations?: {...}
    }

    #rules: [RuleFQN=string]: #PolicyRule  // PolicyRules grouped by this policy

    appliesTo: {
        matchLabels?: {...}         // Label-based component selection
        components?:  [...#Component]  // Explicit component references
    }

    spec: close({...})  // Unified from all #rules specs
}
```

#### Key Relationships

```text
PolicyRule A ──┐
PolicyRule B ──┤──unify──▶ Policy.spec
PolicyRule C ──┘

Policy.appliesTo ──targets──▶ Components (by labels or explicit reference)
Policy ──contains──▶ Module.#policies
```

#### Policy Example

```cue
#policies: {
    "internal-network": network.#NetworkRules & network.#SharedNetwork & {
        appliesTo: {
            matchLabels: {
                "core.opmodel.dev/workload-type": "stateless"
            }
        }
        spec: {
            networkRules: { ... }
            sharedNetwork: { ... }
        }
    }
}
```

**CUE schema**: [`v0/core/policy.cue`](../../v0/core/policy.cue)

### Bundle

A **Bundle** groups multiple Modules for coordinated distribution and management. Where a Module defines a single application, a Bundle defines a system of applications that are versioned and deployed together.

Bundles have their own `#config` and `values` that configure the contained modules as a unit, enabling cross-module configuration (e.g., shared database connection strings, coordinated scaling).

#### What Bundle Infers

- "These **modules belong together** and are deployed as a unit"
- "This provides **cross-module configuration**"
- "This is **versioned and publishable** like a Module"

#### Bundle Structure

```cue
#Bundle: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Bundle"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/bundles/core@v0"
        name!:        string  // e.g., "my-platform"
        fqn:          string  // Computed: "{apiVersion}#{Name}"
        description?: string
    }

    #modules!: [string]: #Module  // Modules included in this bundle
    #config!:    _                // Bundle-level configuration schema
    values:    _                  // Concrete default values
}
```

**CUE schema**: [`v0/core/bundle.cue`](../../v0/core/bundle.cue)

---

## Deployment

### ModuleRelease

A **ModuleRelease** is the concrete deployment instance of a Module. It binds a Module to a target namespace with concrete, closed values that satisfy the module's `#config` schema.

The separation between Module and ModuleRelease is fundamental to OPM's delivery flow. The Module Author publishes a portable definition with sane defaults. The End-user (or deployment system) creates a ModuleRelease that provides environment-specific values. CUE ensures the provided values satisfy the `#config` contract at definition time.

Internally, `_#module` unifies the referenced module with `{#config: values}`, which means the release's concrete values flow through `#config` into component specs. This is what makes `release.components` contain fully-resolved, concrete component definitions rather than templates with unresolved config references.

#### What ModuleRelease Infers

- "This Module is **being deployed** to this namespace with these values"
- "All configuration is **concrete and validated** against the module's contract"
- "This is the **input to the render pipeline**"

#### ModuleRelease Structure

```cue
#ModuleRelease: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "ModuleRelease"

    metadata: {
        name!:      string  // Release name
        namespace!: string  // Target namespace
        fqn:        string  // From #moduleMetadata
        version:    string  // From #moduleMetadata
    }

    #module!:        #Module                // Reference to the Module to deploy
    #moduleMetadata: #module.metadata       // Module metadata (avoids structural cycle with _#module)
    _#module:        #module & {#config: values} // Module evaluated with release values

    components: _#module.#components    // Components resolved with concrete values
    policies?:  [Id=string]: #Policy    // Inherited policies (if any)
    values:     close(#module.#config)  // Concrete values satisfying the contract
}
```

#### ModuleRelease Example

```cue
productionRelease: core.#ModuleRelease & {
    metadata: {
        name:      "basic-module-release"
        namespace: "production"
    }
    #module: basicModule
    values: {
        web: {
            replicas: 3
            image:    "nginx:1.21.6"
        }
        db: {
            image:      "postgres:14.5"
            volumeSize: "10Gi"
        }
    }
}
```

**CUE schema**: [`v0/core/module_release.cue`](../../v0/core/module_release.cue)

### BundleRelease

A **BundleRelease** is the concrete deployment instance of a Bundle. It binds a Bundle to concrete values and tracks deployment phase — the same pattern as ModuleRelease but for multi-module systems.

#### What BundleRelease Infers

- "This Bundle is **being deployed** with these values"
- "Deployment **phase is tracked** (pending, deployed, failed)"

#### BundleRelease Structure

```cue
#BundleRelease: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "BundleRelease"

    metadata: {
        name!: string
    }

    #bundle!: #Bundle                  // Reference to the Bundle to deploy
    values!:  close(#bundle.#spec)     // Concrete values satisfying the bundle spec

    status?: {
        phase:    "pending" | "deployed" | "failed" | "unknown"
        message?: string
    }
}
```

**CUE schema**: [`v0/core/bundle_release.cue`](../../v0/core/bundle_release.cue)

---

## Rendering

### Provider

A **Provider** maps OPM definitions to a specific platform by registering Transformers. It is the bridge between OPM's runtime-agnostic definitions and a concrete platform like Kubernetes, Docker Compose, or a future orchestrator.

A Provider declares its capabilities through its transformer registry. The render pipeline uses `#MatchTransformers` to compute which transformers handle which components, producing a matching plan that drives the rendering phase.

#### What Provider Infers

- "This **platform** can run OPM modules"
- "These are the **transformers** that convert components to platform resources"
- "These are the **Resources and Traits** this platform understands"

#### Provider Structure

```cue
#Provider: {
    apiVersion: "core.opmodel.dev/v0"
    kind:       "Provider"

    metadata: {
        name:        string  // e.g., "kubernetes"
        description: string
        version:     string
        minVersion:  string
    }

    transformers: #TransformerMap  // Registry of transformer FQN → Transformer

    // Auto-computed from transformers:
    #declaredResources:   [...]  // All Resource FQNs this provider handles
    #declaredTraits:      [...]  // All Trait FQNs this provider handles
    #declaredDefinitions: [...]  // Union of resources + traits
}
```

#### Key Relationships

```text
Provider
├── transformers: [FQN]: Transformer
│   ├── #DeploymentTransformer  ──matches──▶ stateless components
│   ├── #StatefulsetTransformer ──matches──▶ stateful components
│   ├── #ServiceTransformer     ──matches──▶ exposed components
│   └── ...
│
└── #MatchTransformers(provider, moduleRelease)
    └── out: { transformerID: { transformer, [matched components] } }
```

#### Provider Example

```cue
#Provider: core.#Provider & {
    metadata: {
        name:        "kubernetes"
        description: "Transforms OPM components to Kubernetes native resources"
        version:     "1.0.0"
        minVersion:  "1.0.0"
    }

    transformers: {
        (transformers.#DeploymentTransformer.metadata.fqn):  transformers.#DeploymentTransformer
        (transformers.#ServiceTransformer.metadata.fqn):     transformers.#ServiceTransformer
        (transformers.#PVCTransformer.metadata.fqn):         transformers.#PVCTransformer
    }
}
```

**CUE schema**: [`v0/core/provider.cue`](../../v0/core/provider.cue)

### Transformer

A **Transformer** converts an OPM Component into a single platform-specific resource (e.g., a Kubernetes Deployment, Service, or PersistentVolumeClaim). Each Transformer produces exactly one output resource — a component that needs multiple platform resources will be matched by multiple transformers.

Transformers use a multi-dimensional matching system: required labels, required Resources, and required Traits must ALL be present on a component for the transformer to match. This matching is computed by `#Matches` and orchestrated by `#MatchTransformers` on the Provider.

#### What Transformer Infers

- "This converts a Component into **one platform-specific resource**"
- "This matches components by **labels and definition FQNs**"
- "This is **registered** in a Provider's transformer registry"

#### Transformer Structure

```cue
#Transformer: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Transformer"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/transformers/kubernetes@v0"
        name!:        string  // e.g., "deployment-transformer"
        fqn:          string  // Computed
        description!: string
    }

    // Matching criteria — ALL must be satisfied
    requiredLabels?:    {...}           // Component must have these labels
    requiredResources:  [FQN=string]: _ // Component must have these Resources
    requiredTraits:     [FQN=string]: _ // Component must have these Traits

    // Optional definitions — used if present, defaults if not
    optionalLabels?:    {...}
    optionalResources:  [FQN=string]: _
    optionalTraits:     [FQN=string]: _

    // The transform function — takes a component, produces one platform resource
    #transform: {
        #component: _              // The matched component
        #context:   #TransformerContext  // Rendering context (name, namespace, labels)
        output:     {...}          // Single platform-specific resource
    }
}
```

#### Matching Flow

```text
Component
├── metadata.labels: {"core.opmodel.dev/workload-type": "stateless", ...}
├── #resources: {"...#Container": ...}
└── #traits: {"...#Scaling": ..., "...#Expose": ...}

                    ▼ #Matches checks:

Transformer (DeploymentTransformer)
├── requiredLabels: {"core.opmodel.dev/workload-type": "stateless"}  ✓
├── requiredResources: {"...#Container": ...}                         ✓
└── requiredTraits: {}                                                ✓
                                                              → MATCH

Transformer (ServiceTransformer)
├── requiredLabels: {}                                                ✓
├── requiredResources: {}                                             ✓
└── requiredTraits: {"...#Expose": ...}                               ✓
                                                              → MATCH
```

One component can match multiple transformers — each produces a different platform resource.

**CUE schema**: [`v0/core/transformer.cue`](../../v0/core/transformer.cue)

---

## Orchestration

### Status

> **Draft** — This construct is not yet finalized.

**Status** is the computation framework that derives module health and diagnostics from configuration values and [StatusProbe](primitives.md#statusprobe) results. Status is evaluated at CUE compile-time for configuration-derived state, and at runtime via probes for live state.

### Lifecycle

> **Draft** — This construct is not yet finalized.

**Lifecycle** orchestrates [LifecycleActions](primitives.md#lifecycleaction) during state transitions (install, upgrade, delete). It handles ordering, conditions, rollback behavior, and phase grouping for the actions it contains.

### Test

> **Draft** — This construct is not yet finalized.

**Test** is a verification framework that validates a module works correctly through its lifecycle. Tests are defined as a separate artifact alongside the module and executed by a dedicated test system, not the OPM CLI.

---

## Tooling

### Config

**Config** is the OPM CLI configuration schema. It validates registry URLs, cache paths, and Kubernetes-specific settings.

```cue
#Config: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Config"

    registry?:   string  // Default CUE module registry
    cacheDir?:   string  // Local cache directory
    providers?:  [string]: _
    kubernetes?: {
        kubeconfig?: string
        context?:    string
        namespace?:  string
    }
}
```

**CUE schema**: [`v0/core/config.cue`](../../v0/core/config.cue)

### Template

**Template** defines a module or bundle initialization template used by the OPM CLI to scaffold new projects. Templates are categorized by complexity level (beginner, intermediate, advanced) and use case.

```cue
#Template: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Template"

    metadata: {
        apiVersion!:  string                                  // Template registry
        name!:        string                                  // Template name
        fqn:          string                                  // Computed
        category!:    "module" | "bundle"                     // What it scaffolds
        level?:       "beginner" | "intermediate" | "advanced"
        description?: string
        useCase?:     string
    }
}
```

**CUE schema**: [`v0/core/template.cue`](../../v0/core/template.cue)
