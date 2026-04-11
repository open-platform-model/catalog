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
        // Defaults to "cluster.local"; overridable via #environment.clusterDomain.
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

Computes all name variants for one component. The four DNS variants cascade automatically from `resourceName`. Overriding `resourceName` (e.g., via a future `nameOverride` mechanism) propagates to all `dns` fields without any further change.

```cue
// catalog/core/v1alpha1/context/context.cue
#ComponentNames: {
    _releaseName:   string
    _namespace:     string
    _clusterDomain: string
    _compName:      string

    // Base Kubernetes resource name for all resources produced by this component.
    // Future: may be overridden by component.metadata.nameOverride.
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

A standalone helper that assembles `#RuntimeContext` from its inputs. Defined in `catalog/core/v1alpha1/helpers/` alongside `#OpmSecretsComponent` and similar helpers. This keeps `#ModuleRelease` readable and makes the context computation independently testable.

```cue
// catalog/core/v1alpha1/helpers/context_builder.cue
#ContextBuilder: {
    // Inputs
    #release:     { name: t.#NameType, namespace: string, uuid: t.#UUIDType }
    #module:      { name: t.#NameType, version: t.#VersionType, fqn: string, uuid: t.#UUIDType }
    #components:  [string]: _   // component key map; values not inspected
    #environment: {
        clusterDomain: *"cluster.local" | string
        routeDomain?:  string
    }

    // Output
    out: #RuntimeContext & {
        release: #release
        module:  #module
        cluster: domain: #environment.clusterDomain
        if #environment.routeDomain != _|_ {
            route: domain: #environment.routeDomain
        }
        components: {
            for compName, _ in #components {
                (compName): {
                    _releaseName:   #release.name
                    _namespace:     #release.namespace
                    _clusterDomain: #environment.clusterDomain
                    _compName:      compName
                }
            }
        }
    }
}
```

---

## `#environment` on `#ModuleRelease`

A new optional input field on `#ModuleRelease`. It carries the deployment-environment properties that `#ContextBuilder` needs. These are distinct from `values` (user application config) and distinct from `metadata` (release identity).

```cue
// catalog/core/v1alpha1/modulerelease/module_release.cue
#ModuleRelease: {
    ...

    // Environment configuration injected by the platform or runtime.
    // Provides cluster- and route-domain information to #ctx.runtime.
    // When absent, clusterDomain defaults to "cluster.local" and route is omitted.
    #environment?: {
        clusterDomain: *"cluster.local" | string
        routeDomain?:  string
        // Open for future environment properties.
        ...
    }

    values: _
}
```

The `#environment` field is populated via `FillPath` in the Go pipeline when the CLI has environment configuration available (e.g., from a flags or config file). When not populated, CUE defaults apply.

---

## File Locations

| New file | Purpose |
| -------- | ------- |
| `catalog/core/v1alpha1/context/context.cue` | `#ModuleContext`, `#RuntimeContext`, `#ComponentNames` |
| `catalog/core/v1alpha1/helpers/context_builder.cue` | `#ContextBuilder` helper |

| Modified file | Change |
| ------------- | ------ |
| `catalog/core/v1alpha1/module/module.cue` | Add `#ctx: ctx.#ModuleContext` |
| `catalog/core/v1alpha1/modulerelease/module_release.cue` | Add `#environment?`; compute and inject `#ctx` via `#ContextBuilder` |
