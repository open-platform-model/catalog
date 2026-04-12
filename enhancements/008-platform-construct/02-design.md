# Design: Module Context, Platform Composition, and Environment Targeting

## Design Goals

- Make release identity (name, namespace, UUID) available to components at definition time
- Make cluster environment (cluster domain, route domain) injectable without polluting `#config`
- Compute all Kubernetes resource names and DNS address variants in a single place
- Centralize content hash computation for immutable resources
- Allow platform teams to inject additional context fields beyond the well-known set
- Keep `#config` strictly as the user-values contract; `#ctx` is the runtime-values contract
- `#Platform` composes a base provider with zero or more capability providers into a unified transformer registry
- `#Platform` contributes platform-level `#ctx` defaults (cluster domain, platform extensions) following the `#ctx` pattern
- `#Environment` is a construct that targets a `#Platform` and contributes environment-level `#ctx` overrides (namespace, route domain)
- `#ModuleRelease` targets an `#Environment` (not a `#Platform` directly)
- Capability modules (K8up, cert-manager) contribute transformers via their existing provider exports — no new pattern needed
- CUE struct unification handles composition naturally; FQN collisions produce CUE errors (correct behavior)
- The matcher receives the composed transformer map unchanged — no matcher changes for composition
- `#Platform` is a pure capability manifest — no runtime connection details (kubeContext, kubeConfig); those are sourced externally

---

## Non-Goals (v1)

- Cross-module context references (e.g., a module reading another module's resource names)
- Bundle-level shared context (deferred — see open questions in README)
- `#TransformerContext` replacement or unification (deferred — see open questions in README)
- Runtime provider discovery (auto-detecting what is installed on the cluster)
- Runtime connection details (kubeContext, kubeConfig) — these belong to a separate runtime config mechanism
- `#Environment` overriding `#config` (values) — environments only contribute to `#ctx`
- Claim/offer changes to `#Transformer`, `#Provider`, and matcher — owned by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/)

---

## Overview

`#ctx` is a definition field on `#Module`. It has two layers: `runtime` (typed as `#RuntimeContext`, OPM-owned and schema-validated) and `platform` (open struct, platform-team-owned). Context inputs originate from `#Platform` (Layer 1, typed as `#PlatformContext`) and `#Environment` (Layer 2, typed as `#EnvironmentContext`). The `#ContextBuilder` merges them with release identity (Layer 3) into the final `#ModuleContext`.

`#ctx` is not authored by module developers. It is computed by `#ContextBuilder` and injected into the module by `#ModuleRelease` during CUE unification. Components in `#components` reference it by name to access deployment identity, environment properties, computed resource names, and DNS addresses.

---

## Context Hierarchy

`#ctx.runtime` fields are populated through a layered override hierarchy. Each layer can set or override fields from the previous layer. The `#ContextBuilder` (see [03-schema.md](03-schema.md)) unifies all layers into the final `#ModuleContext`.

```text
Layer 1: #Platform.#ctx (#PlatformContext)
  Platform-level facts — cluster domain, platform extensions
  e.g., cluster.domain: "cluster.local", platform.defaultStorageClass: "local-path"

Layer 2: #Environment.#ctx (#EnvironmentContext)
  Environment-level overrides — namespace, route domain
  e.g., release.namespace: "dev", route.domain: "dev.example.com"

Layer 3: #ModuleRelease → #ModuleContext
  Release-level identity — name, uuid, module metadata, components
  Can override namespace: metadata.namespace: "media"
```

Each layer's `#ctx` is typed by a schema from [03-schema.md](03-schema.md): `#PlatformContext` (Layer 1), `#EnvironmentContext` (Layer 2), `#ModuleContext` (output). CUE unification merges them naturally — concrete values override defaults, later layers override earlier layers.

See [09-context-flow.md](09-context-flow.md) for a full visual diagram of the information flow from `#Platform` down to rendered resources.

---

## Two Layers of `#ctx`

`#ctx` has two top-level fields with distinct ownership:

```cue
#ctx: {
    runtime:  #RuntimeContext   // OPM-owned, schema-validated
    platform: { ... }           // platform-team-owned, open struct
}
```

### `runtime`

Defined and validated by the OPM catalog. Every field in `runtime` has a known schema and a known computation rule. The `runtime` layer is populated from `#Platform.#ctx.runtime` (`#PlatformContext`) and `#Environment.#ctx.runtime` (`#EnvironmentContext`), with environment overriding platform defaults and release identity added last. The catalog guarantees that `runtime` is always fully populated before components are evaluated. Module authors can rely on every `runtime` field being present.

### `platform`

An open struct with no catalog-defined constraints. Platform teams use this to inject fields that are specific to their environment or tooling. Module authors who target a specific platform can reference `#ctx.platform` fields, with the understanding that those fields are platform-specific and not universally available.

The `platform` layer is populated by merging `#Platform.#ctx.platform` and `#Environment.#ctx.platform` via `#ContextBuilder`. Conventions for naming platform extensions are left to platform teams.

---

## What `runtime` Contains

```cue
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

```cue
#ComponentNames: {
    resourceName: string   // default: "{release}-{component}"

    dns: {
        local:      string // resourceName
        namespaced: string // resourceName.namespace
        svc:        string // resourceName.namespace.svc
        fqdn:       string // resourceName.namespace.svc.clusterDomain
    }

    hashes?: {
        configMaps?: [string]: string   // configmap-name -> content hash
        secrets?:    [string]: string   // secret-name -> content hash
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

---

## Content Hashes

Immutable ConfigMap and Secret names currently include a content hash appended by individual transformers. This computation is scattered. Moving hash computation into `#ctx.runtime.components[name].hashes` creates a single source of truth that both components (for name references) and transformers (for producing the final resource name) can read.

The exact mechanism for populating `hashes` — whether from CUE comprehensions at `#ModuleRelease` evaluation time or from a Go-side pre-pass — is specified in `06-module-integration.md`.

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

## Provider Composition

`#Platform` composes providers via CUE struct unification. Each provider exports a `#transformers` map keyed by transformer FQN. Because FQNs are globally unique (guaranteed by modulePath prefix), maps from different providers merge cleanly into `#composedTransformers`:

```text
Base Kubernetes Provider (#transformers):
  opmodel.dev/.../deployment-transformer@v1:  DeploymentTransformer
  opmodel.dev/.../service-transformer@v1:     ServiceTransformer
  opmodel.dev/.../pvc-transformer@v1:         PVCTransformer
  ... (16 total)

K8up Capability Provider (#transformers):
  opmodel.dev/.../schedule-transformer@v1:      ScheduleTransformer
  opmodel.dev/.../pre-backup-pod-transformer@v1: PreBackupPodTransformer
  ... (4 total)

CUE Unification -> #composedTransformers:
  All 20 transformers in one map
```

If two providers register a transformer with the same FQN, CUE unification errors — which is correct. FQN collision means a genuine conflict.

The `#providers` list is ordered — earlier providers take priority. When multiple transformers from different providers match the same component (same `requiredLabels`, `requiredResources`, `requiredTraits`), the provider order determines precedence. The render pipeline resolves overlapping matches: when multiple transformers match a component for overlapping output types, the transformer from the higher-priority provider wins. The exact conflict detection and resolution rules are specified in `06-module-integration.md`.

The matcher's interface (`#provider: provider.#Provider`) is unchanged. Platform composition is a layer above the matcher — the CLI extracts `#env.#platform.#provider` and passes it to `#MatchPlan` exactly as today.

For the full `#Platform` schema including `#composedTransformers`, `#provider`, and `#declaredResources`, see [03-schema.md](03-schema.md).

---

## Before / After

### Example 1: Jellyfin `publishedServerUrl`

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

The environment operator configures `route.domain` once in the `#Environment` construct. Every module that derives a URL from `#ctx.runtime.route.domain` picks it up automatically. See [05-environment.md](05-environment.md) for the `#Environment` construct.

### Example 2: Platform Composition

**Before (manual merge, no composition point):**

```cue
// User manually creates a merged provider — undocumented, fragile
import (
    k8s "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
)
customProvider: provider.#Provider & {
    metadata: { name: "custom", description: "manual merge", version: "0.1.0" }
    #transformers: k8s.#Provider.#transformers & k8up.#Provider.#transformers
}
// Then somehow pass customProvider to the matcher...
```

**After (`#Platform` + `#Environment`):**

```cue
// .opm/platforms/kind-opm-dev/platform.cue
package kind_opm_dev

import (
    core "opmodel.dev/core/v1alpha1/platform@v1"
    opm "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
    certmgr "opmodel.dev/cert_manager/v1alpha1/providers/kubernetes"
)

#Platform: core.#Platform & {
    metadata: name: "kind-opm-dev"
    type: "kubernetes"
    #ctx: {
        runtime: cluster: domain: "cluster.local"
        platform: defaultStorageClass: "standard"
    }
    #providers: [
        opm.#Provider,       // OPM core transformers (priority 1)
        k8up.#Provider,      // K8up backup transformers
        certmgr.#Provider,   // cert-manager transformers
    ]
}
```

```cue
// .opm/environments/dev/environment.cue
package dev

import (
    core "opmodel.dev/core/v1alpha1/environment@v1"
    platform "opmodel.dev/config@v1/.opm/platforms/kind-opm-dev"
)

#Environment: core.#Environment & {
    metadata: name: "dev"
    #platform: platform.#Platform
    #ctx: runtime: {
        release: namespace: "dev"
        route: domain: "dev.local"
    }
}
// #Environment.#platform.#provider has all composed transformers
// #Environment.#platform.#declaredResources / #declaredTraits list available definitions
```

---

## Related Documents

- [03-schema.md](03-schema.md) — `#Platform`, `#Environment`, `#PlatformContext`, `#EnvironmentContext`, `#ContextBuilder` schemas
- [05-environment.md](05-environment.md) — `#Environment` construct detail: file layout, context resolution, CLI config integration
- [06-module-integration.md](06-module-integration.md) — render pipeline changes, `#ContextBuilder` inputs, content hash population
