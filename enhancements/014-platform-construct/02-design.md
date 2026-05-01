# Design — `#Platform` Construct

## Design Goals

- `#Platform` is a single CUE construct that models a deployment target's identity, context, and registered extensions.
- The composition unit is `#Module`. There is no `#providers` field on `#Platform`.
- The platform's extension surface is a single map — `#registry` — typed to accept `#Module` values via `#ModuleRegistration` entries.
- `#registry` is fillable by the platform CUE file (static) and by the runtime (dynamic) using the same schema field. CUE unification merges both sources.
- All outward platform views (`#knownResources`, `#knownTraits`, `#knownClaims`, `#composedTransformers`, `#matchers`) are computed projections over `#registry`. No view duplicates state.
- Matcher logic lives on `#Platform` directly. `#matchers` is a per-FQN reverse index over `#composedTransformers`; `#PlatformMatch` is a per-deploy walker that resolves a consumer Module's FQN demand against the index. `#Provider` is retired (D12) — the matcher consumes `#composedTransformers` + `#matchers` directly.
- Module installation is a single operator-driven step: a `ModuleRelease` CR triggers `opm-operator` to install `#components` *and* FillPath the Module value into `#registry`. `#ModuleRegistration` carries no install metadata (D11); registration is a pure projection of `#defines`.
- FQN collisions across registered Modules surface as CUE unification errors at platform-evaluation time.

## Non-Goals

- `#Environment` construct, `#ContextBuilder`, and `#ModuleRelease` integration — defined in 008, used unchanged.
- `#PlatformContext` / `#ctx` schema — defined in 008, referenced unchanged.
- Runtime-fill mechanism for `#registry` — schema declared here; mechanism (Strategy B–style Go injection) deferred to a follow-up enhancement.
- Self-service catalog runtime API surface (`opm catalog list`, web UI, deploy-time match resolver) — declarative shape only; runtime is the platform's choice (consistent with 015 design).
- `#PolicyTransformer` registration — deferred until policy redesign converges (`enhancements/012`).
- Migration of `opmodel.dev/opm/v1alpha2/providers/kubernetes` and other provider packages into `#Module` form — separate enhancement.
- Resolution policy when two registered Modules' `#defines.transformers` declare overlapping `requiredClaims` for the same Claim FQN. Today: undefined. A future enhancement may introduce admin-selected default fulfiller, consumer-pinned fulfiller, or registry priority order.
- Policy for unmatched FQNs (Resource / Trait / Claim types used by a deployed module with no renderer registered). Detection is deterministic (D8); the response — fail / warn / drop — is a platform-team policy concern deferred until the catalog `#Policy` redesign (012) converges.

## High-Level Approach

```text
#Platform
├── metadata        identity
├── type            target type ("kubernetes" | ...)
├── #ctx            (from 016 — #PlatformContext)
└── #registry       single dynamic ingress: [Id]: #ModuleRegistration
                     │
                     ▼ projection (CUE comprehensions)
                    #knownResources
                    #knownTraits
                    #knownClaims
                    #composedTransformers
                    #matchers       (D12 — reverse index per demand FQN)

#PlatformMatch       per-deploy walker (D12)
├── platform        the #Platform whose #matchers is consulted
├── module          the consumer Module being deployed
└── matched / unmatched / ambiguous   render plan + diagnostics
```

The platform CUE file lists statically-known Module registrations (e.g. OPM core, vendor operators the admin has installed). The runtime fills additional entries via `FillPath` into `#registry`. The two sources unify by Id key.

Module installation flow (D11):

```text
ModuleRelease CR (with #defines)
   │
   ▼
opm-operator
   ├── installs #components against the cluster
   └── FillPath: #registry[id].#module = <Module>
                          │
                          ▼
                   #knownResources / #knownTraits / #knownClaims
                   #composedTransformers / #matchers
                   recompute automatically
```

Registration is a *consequence* of release. `#ModuleRegistration` carries no install metadata — the operator already has the full `#Module` value via the CR.

### Compatibility detection lives in the matcher

A consumer Module declares no platform requirement. At deploy time the matcher walks the module body for FQN usage — Resource and Trait FQNs from `#components[].#resources` / `#components[].#traits`, Claim FQNs from `#claims` and `#components[].#claims` — and looks each up in `#composedTransformers`. Unmatched FQNs are surfaced as a platform-level signal. There is no `#requires` field on `#Module` (see 015 MS-D5). What to do about an unmatched FQN — fail the deploy, warn and drop, criticality-based escalation — is a platform-team policy concern deferred until the catalog `#Policy` redesign (012) converges. Detection (this enhancement, D8) and policy (future) are independent. Non-Kubernetes runtimes lean on the same mechanism: a compose runtime registers its own transformer Module in `#registry`; resources whose FQN has no compose renderer surface as unmatched (see D9 and 016 D29).

A single registered `#Module` contributes everywhere at once:

| Module slot | Platform view | What it surfaces |
| --- | --- | --- |
| `#defines.resources`    | `#knownResources`         | Catalog of Resource types |
| `#defines.traits`       | `#knownTraits`            | Catalog of Trait types |
| `#defines.claims`       | `#knownClaims`            | Catalog of Claim types (commodity vocabulary) |
| `#defines.transformers` | `#composedTransformers`   | Active rendering registry. Capability fulfilment is registered by each transformer's `requiredClaims` field — `#ComponentTransformer.requiredClaims` for component-level Claims, `#ModuleTransformer.requiredClaims` for module-level Claims (see 015 TR-D5). |
| `#components`           | (consumed at deploy)      | Operator workload to install |
| `#claims`               | (consumed at deploy)      | Module-level needs to resolve |

`#components` and `#claims` are not aggregated at the platform level — they belong to the registered Module's own deployment, not to the platform's catalog surface.

## Schema / API Surface

See [03-schema.md](03-schema.md) for the full CUE definitions. The construct introduces two new types:

- `#Platform` — replaces 008's `#Platform` schema. Inherits `#ctx` typing from enhancement 016's `#PlatformContext`.
- `#ModuleRegistration` — the value type of `#registry` entries.

Lives in: `catalog/core/v1alpha2/platform.cue` (new file under the v1alpha2 flat layout; supersedes the schema sketched in 008).

## Before / After

### Before (008)

```cue
#Platform: core.#Platform & {
    metadata: name: "kind-opm-dev"
    type: "kubernetes"
    #providers: [opm.#Provider, k8up.#Provider, pgop.#Provider]
    #ctx: {
        runtime: cluster: domain: "cluster.local"
        platform: { ... }
    }
}
```

`#providers` is a list. Each entry is a `#Provider` value carrying only transformers. The Postgres operator's `#components` and `#defines` (under 015) have no platform-level home.

### After (014)

```cue
#Platform: core.#Platform & {
    metadata: name: "kind-opm-dev"
    type: "kubernetes"

    #ctx: {
        runtime: cluster: domain: "cluster.local"
        platform: { appDomain: "dev.local" }
    }

    #registry: {
        // OPM core — Module form, registered statically by every k8s platform.
        "opm-core": { #module: opmCore.#Module }

        // K8up — Module form, transformer-only contribution.
        "k8up": { #module: k8up.#Module }

        // Postgres operator — full surface (components + defines.transformers).
        "postgres": {
            #module: pgop.#Module
            presentation: operator: description: "Postgres operator"
        }

        // A golden-path template surfaced to users.
        "stateless-web": {
            #module: webtmpl.#Module
            presentation: template: {
                category: "web"
                examples: small: values: replicas: 2
            }
        }

        // Runtime-discovered modules land here at deploy time. The schema
        // is the same; only the source differs.
    }
}
```

After evaluation:

- `#composedTransformers` contains every transformer from every enabled registration's `#defines.transformers`. Capability fulfilment is implicit: any transformer (`#ComponentTransformer` or `#ModuleTransformer`) whose `requiredClaims` includes a Claim FQN is the supply registration for that Claim (see 015 TR-D5).
- `#knownClaims` lists the standard commodity Claim types the OPM-core Module published in `#defines.claims`.
- `#matchers` is the per-FQN reverse index. The Go pipeline / `opm-operator` instantiates `#PlatformMatch` per deploy, gets back `matched` / `unmatched` / `ambiguous`, and dispatches transformers accordingly (D12).

## File Layout

```text
catalog/core/v1alpha2/
└── platform.cue        // #Platform, #ModuleRegistration (flat package alongside module.cue, component.cue, etc.)
```

008's `#Platform` definition is replaced wholesale. 008's other artefacts (`#PlatformContext`, `#EnvironmentContext`, `#Environment`, `#ContextBuilder`) are lifted into enhancement 016 and referenced from `#Platform.#ctx`.
