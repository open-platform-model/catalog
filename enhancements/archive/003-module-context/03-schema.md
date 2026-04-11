# Schema: `#ctx`, `#RuntimeContext`, and `#ContextBuilder`

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## `#Module` Changes

`#ctx` is added as a definition field on `#Module`. It is abstract at module definition time — its value is supplied by `#ModuleRelease` during unification, not by the module author.

```cue
// catalog/core/v1alpha1/module/module.cue
#Module: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Module"

    metadata: { ... }

    #components: [Id=string]: component.#Component & { ... }
    #policies?:  [Id=string]: policy.#Policy
    #config:     _

    // #ctx is injected by #ModuleRelease. Module authors reference it
    // in #components but never assign values to it directly.
    #ctx: ctx.#ModuleContext

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

Defines the context shape that a `#Platform` contributes (Layer 2). Sets cluster-level defaults and platform-team extensions.

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

Defines the context shape that an `#Environment` contributes (Layer 3). Sets namespace defaults and environment-specific overrides.

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
        // (see enhancement 008 context hierarchy).
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

## `#ContextBuilder`

A standalone helper that assembles `#ModuleContext` from platform, environment, and release inputs. Defined in `catalog/core/v1alpha1/helpers/` alongside `#OpmSecretsComponent` and similar helpers. This keeps `#ModuleRelease` readable and makes the context computation independently testable. The inputs changed from a flat `#environment` struct (enhancement 003 original) to typed `#platform` and `#environment` construct references (enhancement 008). See 008's [05-environment.md](../008-platform-construct/05-environment.md) for the context hierarchy.

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
    out: #ModuleContext & {
        runtime: #RuntimeContext & {
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

## `#env` on `#ModuleRelease`

> **Superseded by enhancement 008, D18.** The original `#environment?` inline field has been replaced by the `#Environment` construct. See [enhancement 008 — 05-environment.md](../008-platform-construct/05-environment.md).

`#ModuleRelease` targets a deployment environment via the `#env` definition field. `#env` references an `#Environment` construct, which carries both the platform reference and environment-level context:

```cue
// catalog/core/v1alpha1/modulerelease/module_release.cue
#ModuleRelease: {
    ...

    // Target environment — carries platform reference and context hierarchy.
    // Imported from .opm/environments/<env>/ by the release file.
    #env: environment.#Environment

    values: _
}
```

Environment properties (cluster domain, route domain, namespace default) are no longer flat fields on `#ModuleRelease` — they live in the `#Environment` and `#Platform` constructs and are resolved via the context hierarchy (CUE defaults → `#Platform.#ctx` → `#Environment.#ctx` → release identity). The `#ContextBuilder` reads from `#env.#platform` and `#env` to assemble the final `#ModuleContext`.

---

## File Locations

| New file | Purpose |
| -------- | ------- |
| `catalog/core/v1alpha1/context/context.cue` | `#ModuleContext`, `#RuntimeContext`, `#ComponentNames` |
| `catalog/core/v1alpha1/helpers/context_builder.cue` | `#ContextBuilder` helper |
| `catalog/core/v1alpha1/platform/platform.cue` | `#Platform` construct (enhancement 008) |
| `catalog/core/v1alpha1/environment/environment.cue` | `#Environment` construct (enhancement 008) |

| Modified file | Change |
| ------------- | ------ |
| `catalog/core/v1alpha1/component/component.cue` | Add optional `resourceName?: t.#NameType` to `metadata` |
| `catalog/core/v1alpha1/module/module.cue` | Add `#ctx: ctx.#ModuleContext` |
| `catalog/core/v1alpha1/modulerelease/module_release.cue` | Add `#env: environment.#Environment`; compute and inject `#ctx` via `#ContextBuilder` |
