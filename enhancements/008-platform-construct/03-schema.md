# Schema Reference

## `#Module` Changes

`#ctx` is added as a definition field on `#Module`. It is abstract at module definition time — its value is supplied by `#ModuleRelease` during unification, not by the module author.

```cue
// catalog/core/v1alpha1/module/module.cue
#Module: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Module"

    metadata: { ... }

    // #ctx is injected by #ModuleRelease. Module authors reference it
    // in #components but never assign values to it directly.
    #ctx: ctx.#ModuleContext

    #components: [Id=string]: component.#Component & { ... }
    #policies?:  [Id=string]: policy.#Policy
    #config:     _

    debugValues: _
}
```

---

## `#Component.metadata` Changes

`resourceName` is added as an optional field on `#Component.metadata`. When set, it overrides the default Kubernetes resource base name (`{release}-{component}`) for all resources produced by this component. The `#ContextBuilder` reads this field when computing `#ComponentNames`.

```cue
// catalog/core/v1alpha1/component/component.cue
#Component: {
    ...

    metadata: {
        name!: t.#NameType

        // Override the Kubernetes resource base name for this component.
        // When absent, resourceName defaults to "{release}-{component}".
        // All DNS variants in #ctx.runtime.components cascade from this value.
        resourceName?: t.#NameType

        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    ...
}
```

---

## `#ModuleContext`

The top-level context struct, defined in a new `context` package under `catalog/core/v1alpha1/context/`.

```cue
// catalog/core/v1alpha1/context/context.cue
#ModuleContext: {
    // runtime contains all OPM-owned, schema-validated fields.
    runtime: #RuntimeContext

    // platform is an open struct for platform-team-defined fields.
    // No catalog constraints apply. Convention governs naming.
    platform: { ... }
}
```

---

## `#PlatformContext`

Defines the context shape that a `#Platform` contributes (Layer 1). Sets cluster-level defaults and platform-team extensions.

```cue
// catalog/core/v1alpha1/context/context.cue
#PlatformContext: {
    runtime: {
        cluster: {
            domain: *"cluster.local" | string
        }
        route?: {
            domain: string
        }
    }
    // Platform-team extensions — open struct for platform-specific fields.
    // Not schema-validated by OPM; conventions left to platform teams.
    platform: { ... }
}
```

---

## `#EnvironmentContext`

Defines the context shape that an `#Environment` contributes (Layer 2). Sets namespace defaults and environment-specific overrides.

```cue
// catalog/core/v1alpha1/context/context.cue
#EnvironmentContext: {
    runtime: {
        release: {
            // Default namespace for releases in this environment.
            // Individual ModuleReleases can override via metadata.namespace.
            namespace: string
        }
        cluster?: {
            // Override platform's cluster domain if this environment
            // targets a cluster with a non-default domain.
            domain: string
        }
        route?: {
            // Environment-specific route domain.
            // Typically varies per environment: "dev.example.com" vs "example.com".
            domain: string
        }
    }
    // Inherits platform extensions; can add env-specific extensions.
    platform: { ... }
}
```

---

## `#RuntimeContext`

The OPM-owned layer. All fields are required to be concrete when the module is rendered.

```cue
// catalog/core/v1alpha1/context/context.cue
#RuntimeContext: {
    // Release identity — mirrors ModuleRelease.metadata
    release: {
        name!:      t.#NameType
        namespace!: string
        uuid!:      t.#UUIDType
    }

    // Module identity — mirrors Module.metadata
    module: {
        name!:    t.#NameType
        version!: t.#VersionType
        fqn!:     t.#ModuleFQNType
        uuid!:    t.#UUIDType
    }

    // Cluster environment
    cluster: {
        // DNS search domain for Kubernetes Services.
        // Defaults to "cluster.local"; overridable via #Platform.#ctx and #Environment.#ctx
        // (see context hierarchy in 02-design.md)
        domain: *"cluster.local" | string
    }

    // Ingress/route environment — absent when no route domain is configured.
    route?: {
        domain: string
    }

    // Per-component computed names. One entry per component key in #components.
    components: [compName=string]: #ComponentNames & {
        _releaseName:   release.name
        _namespace:     release.namespace
        _clusterDomain: cluster.domain
        _compName:      compName
    }
}
```

---

## `#ComponentNames`

Computes all name variants for one component. The four DNS variants cascade automatically from `resourceName`. When a component sets `metadata.resourceName`, `#ContextBuilder` passes it through and it replaces the default; all `dns` fields propagate without any further change.

```cue
// catalog/core/v1alpha1/context/context.cue
#ComponentNames: {
    _releaseName:   string
    _namespace:     string
    _clusterDomain: string
    _compName:      string

    // Base Kubernetes resource name for all resources produced by this component.
    // Defaults to "{release}-{component}". Overridden when the component
    // sets metadata.resourceName — #ContextBuilder passes the override here.
    resourceName: string | *"\(_releaseName)-\(_compName)"

    dns: {
        // resourceName — same-namespace short form
        local:      resourceName
        // resourceName.namespace
        namespaced: "\(resourceName).\(_namespace)"
        // resourceName.namespace.svc
        svc:        "\(resourceName).\(_namespace).svc"
        // resourceName.namespace.svc.clusterDomain
        fqdn:       "\(resourceName).\(_namespace).svc.\(_clusterDomain)"
    }

    // Content hashes for immutable resources produced by this component.
    // Keyed by the logical resource name (not the final hashed Kubernetes name).
    // Absent when the component produces no immutable resources.
    hashes?: {
        configMaps?: [string]: string
        secrets?:    [string]: string
    }
}
```

---

## `#Platform`

New file: `catalog/core/v1alpha1/platform/platform.cue`

`#Platform` combines platform identity, provider composition, and platform-level context. It is the capability manifest for a cluster — what providers are available and in what order.

```cue
// catalog/core/v1alpha1/platform/platform.cue
#Platform: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Platform"

    metadata: {
        name!:        t.#NameType
        description?: string
    }

    // Platform type — all providers must match this type.
    type!: string  // e.g., "kubernetes"

    // Platform-level context contributions (Layer 2 in the context hierarchy).
    // Sets base defaults for #ctx.runtime that environments can override.
    // Schema defined in catalog/core/v1alpha1/context/context.cue (enhancement 003).
    #ctx: ctx.#PlatformContext

    // Provider composition — ordered list, first match wins when multiple
    // transformers match the same component for overlapping output types.
    #providers!: [...provider.#Provider]

    // Composed transformer registry — CUE unification of all providers.
    // FQN collision between providers produces a CUE unification error (correct behavior).
    #composedTransformers: transformer.#TransformerMap & {
        for _, p in #providers {
            p.#transformers
        }
    }

    // The composed provider — passed to the matcher unchanged.
    #provider: provider.#Provider & {
        metadata: {
            name:        metadata.name
            description: "Platform-composed provider"
            type:        type
            version:     "0.0.0"  // Platform version, not individual provider version
        }
        #transformers: #composedTransformers
    }

    // Auto-computed from composed transformers
    #declaredResources: #provider.#declaredResources
    #declaredTraits:    #provider.#declaredTraits
    // #declaredClaims, #composedOffers, #satisfiedClaims added by enhancements 006/007
}
```

---

## `#Environment`

New file: `catalog/core/v1alpha1/environment/environment.cue`

`#Environment` is the user-facing deployment target. It binds a name to a `#Platform` and contributes environment-level `#ctx` overrides. Multiple environments can reference the same platform.

```cue
// catalog/core/v1alpha1/environment/environment.cue
#Environment: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Environment"

    metadata: {
        name!:        t.#NameType
        description?: string
    }

    // Target platform — determines available capabilities and providers.
    // Multiple environments can reference the same platform.
    #platform!: platform.#Platform

    // Environment-level context contributions (Layer 3 in the context hierarchy).
    // Overrides platform-level #ctx defaults for this environment.
    // Schema defined in catalog/core/v1alpha1/context/context.cue (enhancement 003).
    #ctx: ctx.#EnvironmentContext
}
```

### Field Ownership

| Field | Required | Who sets it | Purpose |
| --- | --- | --- | --- |
| `metadata.name` | Yes | Environment author | Human-readable environment identifier |
| `#platform` | Yes | Environment author | Reference to `#Platform` in `.opm/platforms/` |
| `#ctx.runtime.release.namespace` | Yes | Environment author | Default namespace for all releases in this environment |
| `#ctx.runtime.cluster.domain` | No | Environment author | Override platform's cluster domain (rare) |
| `#ctx.runtime.route.domain` | No | Environment author | Environment-specific ingress/route domain |
| `#ctx.platform` | No | Environment author | Additional platform-team extensions for this environment |

---

## `#Provider` Changes

Modified file: `catalog/core/v1alpha1/provider/provider.cue`

Providers gain a required `type` field. All providers within a `#Platform` must share the same type.

```cue
// catalog/core/v1alpha1/provider/provider.cue
#Provider: {
    metadata: {
        name:         t.#NameType
        description:  string
        version:      string
        type!:        string          // NEW: e.g., "kubernetes", "docker-compose"
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }
    // ... (existing #transformers, #declaredResources, #declaredTraits unchanged)
}
```

---

## `#ContextBuilder`

A standalone helper that assembles `#ModuleContext` from platform, environment, and release inputs. Defined in `catalog/core/v1alpha1/helpers/` alongside `#OpmSecretsComponent` and similar helpers. This keeps `#ModuleRelease` readable and makes the context computation independently testable. The inputs are typed `#platform` and `#environment` construct references that resolve cluster domain across the context hierarchy.

```cue
// catalog/core/v1alpha1/helpers/context_builder.cue
#ContextBuilder: {
    // Inputs
    #release:     { name: t.#NameType, namespace: string, uuid: t.#UUIDType }
    #module:      { name: t.#NameType, version: t.#VersionType, fqn: string, uuid: t.#UUIDType }
    #components:  [string]: _   // component key map; values inspected for metadata.resourceName
    #platform:    platform.#Platform
    #environment: environment.#Environment

    // Resolve cluster domain: environment overrides platform default.
    let _clusterDomain = *#environment.#ctx.runtime.cluster.domain |
                         #platform.#ctx.runtime.cluster.domain

    // Output
    out: ctx.#ModuleContext & {
        runtime: ctx.#RuntimeContext & {
            release: #release
            module:  #module
            cluster: domain: _clusterDomain
            if #environment.#ctx.runtime.route != _|_ {
                route: #environment.#ctx.runtime.route
            }
            components: {
                for compName, comp in #components {
                    (compName): {
                        _releaseName:   #release.name
                        _namespace:     #release.namespace
                        _clusterDomain: _clusterDomain
                        _compName:      compName
                        // If the component declares a resourceName override, pass it through.
                        // CUE unification replaces the default in #ComponentNames.
                        if comp.metadata.resourceName != _|_ {
                            resourceName: comp.metadata.resourceName
                        }
                    }
                }
            }
        }
        // Merge platform extensions from both platform and environment layers.
        platform: #platform.#ctx.platform & #environment.#ctx.platform
    }
}
```

---

## `#ModuleRelease` Changes

Modified file: `catalog/core/v1alpha1/modulerelease/module_release.cue`

`#ModuleRelease` targets a deployment environment via `#env`. This replaces enhancement 003's inline `#environment?` field (see 003 D18, 008 D18). The `#ContextBuilder` is invoked inline via `let` bindings, producing the unified module with context injected before component iteration.

```cue
// catalog/core/v1alpha1/modulerelease/module_release.cue
#ModuleRelease: {
    ...

    // Target environment — carries platform reference and context hierarchy.
    // Imported from .opm/environments/<env>/ by the release file.
    #env: environment.#Environment

    let _computedCtx = (helpers.#ContextBuilder & {
        #release:     { name: metadata.name, namespace: metadata.namespace, uuid: metadata.uuid }
        #module:      { name: #moduleMetadata.name, version: #moduleMetadata.version,
                        fqn: #moduleMetadata.fqn, uuid: #moduleMetadata.uuid }
        #components:  #module.#components
        #platform:    #env.#platform
        #environment: #env
    }).out

    let unifiedModule = #module & {
        #config: values
        #ctx:    _computedCtx
    }

    _autoSecrets: (schemas.#AutoSecrets & {#in: unifiedModule.#config}).out

    components: {
        for name, comp in unifiedModule.#components {
            (name): comp
        }
        if len(_autoSecrets) > 0 {
            "opm-secrets": (helpers.#OpmSecretsComponent & {#secrets: _autoSecrets}).out
        }
    }

    values: _
}
```

---

## File Locations

### New Files

| New file | Purpose |
| -------- | ------- |
| `catalog/core/v1alpha1/context/context.cue` | `#ModuleContext`, `#RuntimeContext`, `#PlatformContext`, `#EnvironmentContext`, `#ComponentNames` |
| `catalog/core/v1alpha1/helpers/context_builder.cue` | `#ContextBuilder` helper |
| `catalog/core/v1alpha1/platform/platform.cue` | `#Platform` construct |
| `catalog/core/v1alpha1/environment/environment.cue` | `#Environment` construct |

### Modified Files

| Modified file | Change |
| ------------- | ------ |
| `catalog/core/v1alpha1/component/component.cue` | Add optional `resourceName?: t.#NameType` to `metadata` |
| `catalog/core/v1alpha1/module/module.cue` | Add `#ctx: ctx.#ModuleContext` |
| `catalog/core/v1alpha1/provider/provider.cue` | Add required `type!: string` to `metadata` |
| `catalog/core/v1alpha1/modulerelease/module_release.cue` | Replace `#environment?` with `#env: environment.#Environment`; compute and inject `#ctx` via `#ContextBuilder` |
| `catalog/core/v1alpha1/helpers/context_builder.cue` | Replace flat `#environment` input with typed `#platform` + `#environment` inputs; output `#ModuleContext` instead of `#RuntimeContext` |
