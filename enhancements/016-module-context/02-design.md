# Design — `#ctx` Module Runtime Context

## Design Goals

- `#ctx` is a single runtime-context channel on `#Module`, parallel to `#config` but owned by the catalog and the platform — never by the operator.
- Two-layer shape: `runtime` (OPM-owned, schema-validated, fully populated when components evaluate) and `platform` (open struct, platform-team-owned, no catalog constraints).
- Layered hierarchy: `#Platform.#ctx` (Layer 1) → `#Environment.#ctx` (Layer 2) → `#ModuleRelease` identity (Layer 3) → final `#ModuleContext`.
- Every field in `runtime` is derivable from layered inputs. Module authors never write to `#ctx`; they only read it.
- All per-component name variants (`resourceName`, `dns.local`, `dns.namespaced`, `dns.svc`, `dns.fqdn`) cascade from a single base, so a `metadata.resourceName` override propagates everywhere automatically.
- Each component sees its own `#ComponentNames` entry as `#names`, injected by `#ContextBuilder`. Components read `#names.dns.fqdn` from inside their own body without retyping their map key. Cross-component reads still go through `#ctx.runtime.components[<otherKey>]`.
- Computation lives in CUE via a `#ContextBuilder` helper. The catalog is independently testable as a CUE value; no Go-side wiring is required for the core hierarchy resolution.
- `#config` and `#ctx` stay strictly separate. `#config` is what the operator supplies; `#ctx` is what the runtime computes.

## Non-Goals

- `#Platform` composition (`#registry`, computed views over registered Modules) — owned by 014.
- `#Module`'s top-level slot list (`#components`, `#claims`, `#defines`, etc.) — owned by 015.
- `#TransformerContext` migration / unification with `#ctx` — deferred. They overlap (release name, namespace, component name, label computation) but are computed independently for now; a follow-up enhancement will resolve the relationship.
- Bundle-level shared context (cross-module references — module A reads module B's computed names) — deferred.
- Content hashes for immutable ConfigMaps and Secrets. The hash slot was deliberately removed from this enhancement (see D31); transformers continue to compute and bake hashes on their own until a concrete need surfaces a module-readable hash channel.
- Runtime connection details (kubeContext, kubeConfig). These belong to a separate runtime-config mechanism and are not part of `#ctx`.
- `#Environment` overriding `#config` (values). Environments only contribute to `#ctx`.

## High-Level Approach

`#ctx` is a CUE definition field on `#Module`:

```cue
#Module: {
    ...
    #ctx: ctx.#ModuleContext   // computed and injected by #ModuleRelease
    ...
}
```

The value of `#ctx` has two named layers:

```text
#ctx
├── runtime         OPM-owned, schema-validated, always fully populated
│   ├── release     { name, namespace, uuid }
│   ├── module      { name, version, fqn, uuid }
│   ├── cluster     { domain }
│   ├── route?      { domain }
│   └── components  [name]: #ComponentNames
└── platform        platform-team-owned, open struct, no catalog constraints
    └── ...         e.g. backup.backends.*, tls.issuers.*, routing.gateways.*, appDomain
```

`runtime` carries every fact the catalog can model. The catalog guarantees these fields are present when components evaluate. Module authors write `#ctx.runtime.cluster.domain` knowing it will resolve.

`platform` is the open struct that platform teams populate. The catalog imposes no naming convention. A platform that publishes a backup commodity sets `#ctx.platform.backup.backends.<name>: {...}`. A module written against that platform reads `#ctx.platform.backup.backends[claim.backend]`. Platform-extension naming conventions emerge from real platforms; the catalog does not pre-impose them.

### Vocabulary stance

`#ctx.runtime` uses Kubernetes vocabulary as the canonical substrate. `cluster.domain`, `release.namespace`, and the `dns.{local,namespaced,svc,fqdn}` quartet are all k8s-shaped fields treated as the universal contract that every runtime presents. The choice is deliberate: k8s is the most expressive deploy substrate the project targets today; building a runtime-agnostic abstraction before a second concrete runtime exists tends to least-common-denominator outcomes (see D29). Non-Kubernetes runtimes (compose, nomad, …) interpret the same field names by mapping to local concepts — see "Non-Kubernetes Runtime Semantics" below. Cross-runtime portability for ecosystem-supplied resolutions (URLs, peer addresses, connection strings) flows through Claim `#status` (015 CL-D15), not through `runtime` field abstractions.

### Layered hierarchy

`runtime` is populated by merging three layers in order. Each layer can set fields the previous layer left open or override fields the previous layer set.

```text
Layer 1 — #Platform.#ctx (typed #PlatformContext)
   Cluster-level facts
   e.g. cluster.domain "cluster.local", platform.defaultStorageClass

Layer 2 — #Environment.#ctx (typed #EnvironmentContext)
   Environment-level overrides + namespace default
   e.g. release.namespace "dev", route.domain "dev.example.com"

Layer 3 — #ModuleRelease identity
   Per-release facts: name, namespace (overrides env default), uuid, module metadata
   Plus per-component computed names (#ComponentNames) keyed off the
   release+component+namespace+cluster.domain inputs.

Output — #ModuleContext (the value of #Module.#ctx)
```

The hierarchy is realised by `#ContextBuilder`, a helper in `core/v1alpha2/` (flat package alongside the rest of v1alpha2). It takes the platform, the environment, the release identity, the module identity, and the component map, and produces the final `#ModuleContext`.

The `platform` extension layer (the open struct) is also merged: `#Platform.#ctx.platform` and `#Environment.#ctx.platform` unify (CUE struct merge of two open structs). Environments can add or refine platform facts beyond what the platform supplies.

### Per-component computed names

For every component in `#Module.#components`, `#ContextBuilder` adds an entry to `#ctx.runtime.components` keyed by the component's name. The entry's shape is `#ComponentNames`:

```cue
#ComponentNames: {
    // Base Kubernetes resource name. Defaults to "{release}-{component}".
    // Overridden when the Component sets metadata.resourceName.
    resourceName: string

    dns: {
        local:      string   // resourceName
        namespaced: string   // resourceName.namespace
        svc:        string   // resourceName.namespace.svc
        fqdn:       string   // resourceName.namespace.svc.<clusterDomain>
    }
}
```

All four DNS forms cascade from `resourceName` — overriding the base name automatically propagates. `metadata.resourceName` on `#Component` is the single point of override; `#ContextBuilder` reads it and unifies it into the per-component entry. Authors never have to override the DNS forms separately.

The same per-component entry is also injected back into the component itself as `#names`, so the component body can read `#names.resourceName` and `#names.dns.*` directly:

```cue
"router": {
    spec: container: env: {
        SELF_FQDN: { name: "SELF_FQDN", value: #names.dns.fqdn }
    }
}

for _srvName, _c in #config.servers {
    "server-\(_srvName)": {
        spec: container: env: {
            SELF: { name: "SELF", value: #names.dns.fqdn }
        }
    }
}
```

`#names` is exactly `#ctx.runtime.components[<this component's key>]`. The two surfaces are kept in lock-step by `#ContextBuilder` (same `_componentNames` let binding feeds both). See D32 for rationale.

### Where `#ctx` is computed and injected

`#ModuleRelease` invokes `#ContextBuilder` inline via `let` bindings, then unifies the result into the module along with `values`:

```cue
#ModuleRelease: {
    metadata: { name, namespace, uuid, ... }
    #env:    environment.#Environment       // imported from .opm/environments/<env>/
    #module: module.#Module
    values:  _

    let _computedCtx = (helpers.#ContextBuilder & {
        #release:     { name: metadata.name, namespace: metadata.namespace, uuid: metadata.uuid }
        #module:      { name: #moduleMetadata.name, version: ..., fqn: ..., uuid: ... }
        #components:  #module.#components
        #platform:    #env.#platform
        #environment: #env
    }).out

    let unifiedModule = #module & {
        #config: values
        #ctx:    _computedCtx
    }

    components: { for name, comp in unifiedModule.#components { (name): comp } }
}
```

By the time `components` are extracted, `#ctx` is fully resolved. The render pipeline iterates components without further context wiring on the CUE side.

## How `#ctx` differs from `#config`

| | `#config` | `#ctx` |
|---|---|---|
| Who supplies values | Operator (via `ModuleRelease.values`) | Runtime (via `#ContextBuilder` from layered inputs) |
| Content | Application configuration | Deployment identity + cluster environment |
| Schema constraint | OpenAPIv3-compatible (no CUE templating) | CUE-native (computed fields, let bindings) |
| Module author writes it | No (it's the schema; values come from operator) | No (computed by `#ContextBuilder`) |
| Module author reads it | Yes, via `#config.fieldName` | Yes, via `#ctx.runtime.<…>` and `#ctx.platform.<…>` |

Both fields are CUE definition fields (`#`-prefixed) so they are excluded from `cue export` output. Both are abstract at module-definition time and become concrete only after `#ModuleRelease` unification.

## Integration with `#Platform` and `#Module`

- **014 (Platform)** types its `#ctx` field as `ctx.#PlatformContext` (defined here). The platform CUE file populates `#ctx.runtime.cluster.domain` and `#ctx.platform.<…>` extensions.
- **015 (Module)** introduces `#ctx: ctx.#ModuleContext` as a definition field on `#Module`, parallel to `#config`. Module authors reference `#ctx.runtime` and `#ctx.platform` inside `#components`.
- **`#Component.metadata.resourceName`** (introduced here, used by `#ComponentNames`) is the single override point for resource names. All DNS variants cascade automatically.

## Information flow (visual)

```text
                          AUTHORING TIME
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐

  #Platform                                   Layer 1 — #PlatformContext
    metadata, type
    #ctx.runtime.cluster.domain      "cluster.local"
    #ctx.runtime.route?.domain       (optional default)
    #ctx.platform                    open struct (storage class, backup backends, …)

  #Environment                                Layer 2 — #EnvironmentContext
    #platform → #Platform
    #ctx.runtime.release.namespace   "dev"
    #ctx.runtime.cluster?.domain     (rare override)
    #ctx.runtime.route?.domain       "dev.example.com"
    #ctx.platform                    env-specific extensions

└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

                          DEPLOY TIME
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐

  #ModuleRelease                              Layer 3 — release identity
    metadata.name, namespace, uuid
    #env → #Environment
    #module → #Module
    values → #config

       │
       ▼
  #ContextBuilder
    INPUTS: #release, #module, #components, #platform, #environment
    MERGE:  Platform runtime → Environment runtime → Release identity → Component names
            Platform.platform & Environment.platform (open-struct unification)
    OUTPUT: #ModuleContext

       │
       ▼
  unifiedModule = #module & {
                    #config:     values
                    #ctx:        <computed.ctx>
                    #components: <computed.injections>   // adds #names per component
                  }

       │
       ▼
  components: extracted with #ctx fully resolved and
              each component's own #names already set → render pipeline

└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

## Layer-resolution example

Concrete example: Jellyfin release in `dev` environment on `kind-opm-dev` platform.

```text
┌──────────────────┬─────────────────┬─────────────┬────────────────┐
│                  │ cluster.domain  │ namespace   │ route.domain   │
├──────────────────┼─────────────────┼─────────────┼────────────────┤
│ Layer 1 Platform │ "cluster.local" │ -           │ -              │
│ Layer 2 Env      │ -               │ "dev"       │ "dev.local"    │
│ Layer 3 Release  │ -               │ "media" *   │ -              │
├──────────────────┼─────────────────┼─────────────┼────────────────┤
│ Result           │ "cluster.local" │ "media"     │ "dev.local"    │
└──────────────────┴─────────────────┴─────────────┴────────────────┘

* Release metadata.namespace overrides environment default
```

## Non-Kubernetes Runtime Semantics

`#ctx.runtime` uses Kubernetes vocabulary as the canonical substrate. Non-k8s runtimes (compose, nomad, future targets) interpret each field by mapping to local concepts. The same module body reads `#ctx.runtime.components.metadata.dns.svc` and gets a string; on Kubernetes the string resolves via kube-dns Service discovery, on Docker Compose the same string is a network alias on the compose service. The string doesn't need to be runtime-shaped to work — it just needs to be a stable identifier the runtime can route on.

### Field mapping

| `#ctx.runtime` field | Kubernetes meaning | Docker Compose mapping | HashiCorp Nomad mapping |
| --- | --- | --- | --- |
| `release.name` | Release identifier | Compose project name component | Nomad job name component |
| `release.namespace` | Kubernetes namespace | Compose project name (often `release.name`) | Nomad namespace |
| `release.uuid` / `release.environment` | Identity / env label | Identity / env label | Identity / env label |
| `cluster.domain` | DNS search domain (`cluster.local`) | Empty or `"local"` (informational only) | Consul-domain-equivalent if integrated |
| `route.domain` | Ingress / Gateway hostname suffix | Reverse-proxy hostname suffix (Traefik etc.) | External proxy hostname suffix |
| `components.<x>.resourceName` | Kubernetes resource basename | Compose service name | Nomad task / group name |
| `components.<x>.dns.local` | Same-namespace short-form | Network alias (primary) | Service registration short-form |
| `components.<x>.dns.namespaced` | `name.namespace` short-form | Network alias (secondary) | `task.namespace` consul form |
| `components.<x>.dns.svc` | `name.namespace.svc` form | Network alias (tertiary) | `task.namespace.service.consul` form |
| `components.<x>.dns.fqdn` | Fully qualified `name.namespace.svc.<clusterDomain>` | Network alias (full form) | Fully qualified consul form |

Compose accepts arbitrary network aliases per service; the four `dns.*` forms can all be aliases on the same service. Nomad relies on Consul service registration for the same naming surface.

### Unmatched Resources / Claims

Resources, Traits, or Claims that have no transformer renderer in a non-k8s platform are detected mechanically by the matcher (see 014 D8). What to do about an unmatched FQN — fail the deploy, warn and drop, or silently skip — is a platform-team policy concern, deferred until the catalog `#Policy` redesign (012) converges. Modules do not declare platform compatibility; the matcher reports unmatched FQNs and the platform applies its policy.

### Why k8s-canonical instead of a target split

An earlier design considered splitting `#ctx.runtime` into `runtime.universal` + `runtime.kubernetes` / `runtime.compose` / `runtime.nomad` subtrees. The split would have made portability honest at the cost of every module body needing target-specific reads (or wrapping every field access in a claim). With k8s-canonical + claim-based portability via 015 CL-D15 (`#status`), the split is unnecessary: the runtime fields stay legible across targets, and *cross-runtime* resolutions (public URLs, peer addresses, DB connection strings) flow through the rich `#status` channel. See D30.

## Before / After

### Before — Jellyfin's `publishedServerUrl`

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

### After — derive from `#ctx`

```cue
// modules/jellyfin/components.cue
if #ctx.runtime.route != _|_ {
    JELLYFIN_PublishedServerUrl: {
        name:  "JELLYFIN_PublishedServerUrl"
        value: "https://jellyfin.\(#ctx.runtime.route.domain)"
    }
}
```

The environment operator configures `route.domain` once on `#Environment`. Every module that derives a URL from `#ctx.runtime.route.domain` picks it up automatically. No `#config` field, no per-release manual computation.

## File Layout

```text
catalog/core/v1alpha2/
├── context.cue                  // #ModuleContext, #PlatformContext, #EnvironmentContext,
│                                // #RuntimeContext, #ComponentNames
├── environment.cue              // #Environment (minimum form: metadata + #ctx + #platform)
└── context_builder.cue          // #ContextBuilder
```

Files live in the flat `v1alpha2` package; no subdirectories.

`#Platform` (014) and `#Module` (015) reference these definitions through their `#ctx` field types.
