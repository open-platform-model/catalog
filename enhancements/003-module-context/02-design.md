# Design: Two-Layer Module Context

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Design Goals

- Make release identity (name, namespace, UUID) available to components at definition time
- Make cluster environment (cluster domain, route domain) injectable without polluting `#config`
- Compute all Kubernetes resource names and DNS address variants in a single place
- Centralize content hash computation for immutable resources
- Allow platform teams to inject additional context fields beyond the well-known set
- Keep `#config` strictly as the user-values contract; `#ctx` is the runtime-values contract

---

## Non-Goals (v1)

- Cross-module context references (e.g., a module reading another module's resource names)
- Bundle-level shared context (deferred — see open questions in README)
- `#TransformerContext` replacement or unification (deferred — see open questions in README)

---

## Overview

`#ctx` is a new definition field on `#Module`. It is a well-known struct whose schema is defined in the catalog. Components in `#components` reference it by name to access deployment identity, environment properties, computed resource names, and DNS addresses.

`#ctx` is not authored by module developers. It is injected by the runtime — specifically by `#ModuleRelease` — during CUE unification. The injection uses the same `FillPath` pattern as `values` filling `#config`.

---

## Two Layers

`#ctx` has two top-level fields with distinct ownership:

```
#ctx: {
    runtime:  #RuntimeContext   // OPM-owned, schema-validated
    platform: { ... }           // platform-team-owned, open struct
}
```

### `runtime`

Defined and validated by the OPM catalog. Every field in `runtime` has a known schema and a known computation rule. The catalog guarantees that `runtime` is always fully populated before components are evaluated. Module authors can rely on every `runtime` field being present.

### `platform`

An open struct with no catalog-defined constraints. Platform teams use this to inject fields that are specific to their environment or tooling. Module authors who target a specific platform can reference `#ctx.platform` fields, with the understanding that those fields are platform-specific and not universally available.

The `platform` layer is populated by merging `#Platform.#ctx.platform` and `#Environment.#ctx.platform` via `#ContextBuilder` (see [enhancement 008](../008-platform-construct/02-design.md)). Conventions for naming platform extensions are left to platform teams.

---

## What `runtime` Contains

```
runtime: {
    release: {
        name:      string    // ModuleRelease.metadata.name
        namespace: string    // ModuleRelease.metadata.namespace
        uuid:      string    // ModuleRelease.metadata.uuid
    }

    module: {
        name:    string      // Module.metadata.name
        version: string      // Module.metadata.version
        fqn:     string      // Module.metadata.fqn
        uuid:    string      // Module.metadata.uuid
    }

    cluster: {
        domain: string       // default "cluster.local"; overridable via #Platform.#ctx / #Environment.#ctx
    }

    route?: {
        domain: string       // e.g., "home.example.com"; absent when not configured
    }

    // One entry per component in the module.
    // Computed from release name, component name, and cluster domain.
    components: [compName=string]: #ComponentNames
}
```

### `#ComponentNames`

The per-component sub-struct is the centerpiece of the runtime context. It takes the four primitive inputs — release name, component name, namespace, and cluster domain — and derives all useful name variants from them.

`resourceName` is the base Kubernetes name for all resources produced by the component. It defaults to `{release}-{component}`. A component can override this by setting `metadata.resourceName` on its `#Component` definition — `#ContextBuilder` reads the override and passes it into `#ComponentNames`, where it replaces the default. All `dns` variants cascade from `resourceName` automatically, so a single override propagates everywhere.

```
#ComponentNames: {
    resourceName: string   // default: "{release}-{component}"

    dns: {
        local:      string // resourceName
        namespaced: string // resourceName.namespace
        svc:        string // resourceName.namespace.svc
        fqdn:       string // resourceName.namespace.svc.clusterDomain
    }

    hashes?: {
        configMaps?: [string]: string   // configmap-name → content hash
        secrets?:    [string]: string   // secret-name → content hash
    }
}
```

The `dns` variants cover the four common forms used in Kubernetes workloads:

| Variant | Example | Use case |
| ------- | ------- | -------- |
| `local` | `jellyfin-jellyfin` | Same-namespace reference, short form |
| `namespaced` | `jellyfin-jellyfin.media` | Same-namespace, explicit namespace |
| `svc` | `jellyfin-jellyfin.media.svc` | Cross-namespace |
| `fqdn` | `jellyfin-jellyfin.media.svc.cluster.local` | Fully qualified, cross-cluster |

### Content hashes

Immutable ConfigMap and Secret names currently include a content hash appended by individual transformers. This computation is scattered. Moving hash computation into `#ctx.runtime.components[name].hashes` creates a single source of truth that both components (for name references) and transformers (for producing the final resource name) can read.

The exact mechanism for populating `hashes` — whether from CUE comprehensions at `#ModuleRelease` evaluation time or from a Go-side pre-pass — is specified in `04-pipeline-changes.md`.

---

## How `#ctx` Is Separate from `#config`

`#config` and `#ctx` are parallel inputs to `#Module`:

| | `#config` | `#ctx` |
| --- | --- | --- |
| Who supplies values | Operator (via `ModuleRelease.values`) | Runtime (via `#ModuleRelease` computation) |
| Content | Application configuration | Deployment identity and environment |
| Schema constraint | OpenAPI v3-compatible (no templating) | CUE-native (computed fields, let bindings) |
| Required for static analysis | No (abstract until deploy) | No (abstract until deploy) |
| Module author reads it | Yes, via `#config.fieldName` | Yes, via `#ctx.runtime.release.name` |

Both fields are definition fields on `#Module` (prefixed with `#`). Both are abstract at module definition time and become concrete only after `#ModuleRelease` unification.

---

## Before and After: Jellyfin

The `publishedServerUrl` field in the Jellyfin module is the canonical example of a value that is derived from runtime context but is currently forced into `#config`.

**Before:**

```cue
// modules/jellyfin/module.cue
#config: {
    // Operator must supply this manually even though it is fully derivable.
    publishedServerUrl?: string
}

// modules/jellyfin/components.cue
if #config.publishedServerUrl != _|_ {
    JELLYFIN_PublishedServerUrl: {
        name:  "JELLYFIN_PublishedServerUrl"
        value: #config.publishedServerUrl
    }
}
```

**After:**

```cue
// modules/jellyfin/components.cue
// Derived from context — no operator input required.
if #ctx.runtime.route != _|_ {
    JELLYFIN_PublishedServerUrl: {
        name:  "JELLYFIN_PublishedServerUrl"
        value: "https://jellyfin.\(#ctx.runtime.route.domain)"
    }
}
```

The environment operator configures `route.domain` once in the `#Environment` construct. Every module that derives a URL from `#ctx.runtime.route.domain` picks it up automatically. See [enhancement 008](../008-platform-construct/05-environment.md) for the `#Environment` construct.
