# Schema — `#Platform` Construct

## Summary

Four CUE definitions land in `core/v1alpha2`:

- `#Platform` — `core/v1alpha2/platform.cue` (replaces 008's `#Platform` schema)
- `#ModuleRegistration` — same file
- `#PlatformMatch` — same file (per-deploy match construct)
- `#ComponentTransformer` — `core/v1alpha2/transformer.cue` (replaces v1alpha1's single `#Transformer`)

`#Platform`, `#ModuleRegistration`, and `#PlatformMatch` cover Resource/Trait demand only at this layer. `#ComponentTransformer` is the sole transformer primitive introduced here — it fires once per matching `#Component`. Sibling enhancement [015](../015-claims/) extends the schema with `#Claim`, `#ModuleTransformer`, `#defines.claims`, status writeback, and the corresponding widenings of `#composedTransformers`, `#matchers`, and `#PlatformMatch`.

The `#Module` shape (eight-slot flat structure) and the `#defines.{resources, traits, transformers}` publication channel are introduced together with this enhancement and described in [015](../015-claims/05-defines-channel.md); 014 references the slots it consumes.

## `#Platform`

```cue
package v1alpha2

// #Platform: A deployment target's identity, context, and registered
// extensions. Composition unit is #Module (registered via #registry).
// All outward views are computed projections over #registry.
//
// `#ComponentTransformer` and `#TransformerMap` are siblings in the
// flat v1alpha2 package — no import needed. (015 adds `#ModuleTransformer`
// and widens `#TransformerMap` to the union.)
#Platform: {
    apiVersion: "opmodel.dev/core/v1alpha2"
    kind:       "Platform"

    metadata: {
        name!:        #NameType
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Target type. Every registered Module's transformers must be
    // compatible with this type. (Compatibility check deferred — for now
    // type is informational; future enhancement may enforce. See OQ2.)
    type!: string

    // Platform-level context. Schema defined in enhancement 016 (#PlatformContext).
    #ctx: #PlatformContext

    // The single dynamic ingress for platform extensions.
    // Filled by:
    //   1. Platform CUE file (admin-authored static registrations).
    //   2. Runtime injection — opm-operator reconciles ModuleRelease CRs
    //      and FillPaths the Module value into #registry[id].#module.
    //      Installation of #components and registration of #defines are
    //      a single operator-driven step (see D11).
    // Both sources unify by Id key.
    //
    // Id keys MUST be kebab-case (#NameType — D16). Convention is to set
    // Id to #module.metadata.name. Static + runtime writes to the same Id
    // unify; concrete-value disagreement produces _|_ at platform-eval
    // time (D15). The opm-operator reconciler surfaces such conflicts in
    // ModuleRelease.status.conditions.
    #registry: [Id=#NameType]: #ModuleRegistration

    // ---- Computed views over #registry ----

    // Catalog views — type definitions published by registered Modules.
    // Each is keyed by FQN. FQN collisions across Modules surface as CUE
    // unification errors (correct behaviour — forces conflict resolution
    // at registration time).
    //
    // The pattern constraint and the comprehension live as siblings inside
    // the struct (NOT as `[FQN=string]: T & {comprehension}` — that form
    // treats the comprehension as a per-value constraint and the map stays
    // empty). Verified by experiments/002 finding 2.
    #knownResources: {
        [FQN=string]: #Resource
        for _, reg in #registry
        if reg.enabled
        if reg.#module.#defines != _|_
        if reg.#module.#defines.resources != _|_
        for fqn, v in reg.#module.#defines.resources {
            (fqn): v
        }
    }

    #knownTraits: {
        [FQN=string]: #Trait
        for _, reg in #registry
        if reg.enabled
        if reg.#module.#defines != _|_
        if reg.#module.#defines.traits != _|_
        for fqn, v in reg.#module.#defines.traits {
            (fqn): v
        }
    }

    // #knownClaims is added by 015 once #defines.claims exists.

    // Active rendering registry — all transformers from all enabled Modules.
    // Capability fulfilment for Resources/Traits is registered implicitly:
    // a transformer whose requiredResources / requiredTraits includes a
    // primitive FQN is the supply registration for that primitive (D7).
    // 015 widens #TransformerMap to the union (#ComponentTransformer |
    // #ModuleTransformer) and adds the requiredClaims supply path.
    // Multi-fulfiller is forbidden — see #matchers._invalid below (D13).
    #composedTransformers: #TransformerMap & {
        for _, reg in #registry
        if reg.enabled
        if reg.#module.#defines != _|_
        if reg.#module.#defines.transformers != _|_
        for fqn, v in reg.#module.#defines.transformers {
            (fqn): v
        }
    }

    // ---- Match index (D12) ----

    // Reverse index from #composedTransformers' required* fields.
    // Key = FQN of a primitive that some transformer fulfils; value =
    // candidate transformers for that FQN. Empty/missing FQN at lookup
    // time = unmatched (D8). Multi-candidate is forbidden (D13) — the
    // _invalid list captures any FQN with > 1 fulfiller, and the
    // _noMultiFulfiller constraint forces _|_ at platform-eval time.
    //
    // Resources and Traits are component-scope only (CL-D11); only
    // #ComponentTransformer can fulfil them. 015 adds a `claims` sub-map
    // populated from transformer requiredClaims (component-level via
    // #ComponentTransformer, module-level via #ModuleTransformer).
    //
    // Pre-compute candidate maps as `let` bindings so _invalid can iterate
    // them directly. Iterating the published `resources` / `traits` fields
    // fails under `cue vet -c` with "incomplete type list" because the
    // field type is `[FQN]: [...#ComponentTransformer]` — an open
    // value-list — which CUE refuses to range over. (experiments/002
    // finding 4.) List comprehensions yield via `{t}` — the trailing
    // `t,` form is invalid CUE (experiments/002 finding 1).
    #matchers: {
        let _resourceFqns = {
            for _, t in #composedTransformers
            if t.requiredResources != _|_
            for fqn, _ in t.requiredResources {
                (fqn): _
            }
        }
        let _traitFqns = {
            for _, t in #composedTransformers
            if t.requiredTraits != _|_
            for fqn, _ in t.requiredTraits {
                (fqn): _
            }
        }

        let _resourceCandidates = {
            for fqn, _ in _resourceFqns {
                (fqn): [
                    for _, t in #composedTransformers
                    if t.requiredResources != _|_
                    if t.requiredResources[fqn] != _|_ {t},
                ]
            }
        }
        let _traitCandidates = {
            for fqn, _ in _traitFqns {
                (fqn): [
                    for _, t in #composedTransformers
                    if t.requiredTraits != _|_
                    if t.requiredTraits[fqn] != _|_ {t},
                ]
            }
        }

        resources: {[FQN=string]: [...#ComponentTransformer]} & _resourceCandidates
        traits:    {[FQN=string]: [...#ComponentTransformer]} & _traitCandidates

        // D13 — forbid multi-fulfiller. Any FQN with > 1 candidate lands
        // in _invalid; the _noMultiFulfiller constraint then unifies
        // len(_invalid) with concrete 0, producing _|_ when non-empty.
        // Hidden fields — diagnostic surface for tooling, not for authors.
        // Iterates the let-binding candidate maps (concrete) rather than
        // the typed published fields.
        //
        // 015 adds `claims` to both `_invalid` and the `_noMultiFulfiller`
        // sum once Claim-fulfilling transformers exist.
        _invalid: {
            resources: [
                for fqn, ts in _resourceCandidates if len(ts) > 1 {fqn},
            ]
            traits: [
                for fqn, ts in _traitCandidates if len(ts) > 1 {fqn},
            ]
        }
        _noMultiFulfiller: 0 & (len(_invalid.resources) + len(_invalid.traits))
    }
}
```

> **Diagnostic split:** During implementation, consider exposing a `#PlatformBase` (every projection except `_noMultiFulfiller`) alongside the strict `#Platform`. Tests that need to *inspect* `_invalid` populated cannot use the strict form because the constraint short-circuits to `_|_` before any field is readable. The split is a testing convenience; production schemas use `#Platform`. See `experiments/002-platform-construct/22_platform.cue` for the working pattern.

## `#ModuleRegistration`

```cue
// #ModuleRegistration: A single entry in #Platform.#registry.
// Pure projection of "this Module's primitives are visible on this
// platform". Carries no install/deploy metadata — installation of
// #components is owned by ModuleRelease + opm-operator (D11).
#ModuleRegistration: {
    // The Module definition. Static path: imported from a CUE package.
    // Runtime path: FillPath-injected by opm-operator after a
    // ModuleRelease CR is reconciled.
    #module!: #Module

    // Enable/disable without removing the entry. Default true.
    // When false, every #Platform projection that walks #registry
    // (#knownResources, #knownTraits, #composedTransformers, #matchers —
    // and #knownClaims once 015 lands) skips this entry — the Module's
    // primitives are completely hidden from the platform until enabled
    // flips back to true (D14). Use case: stage a registration via
    // FillPath, leave it dark until a follow-up reconcile flips the flag.
    enabled: bool | *true

    // Optional self-service catalog metadata. Carries platform-curation
    // data (category/tags/examples) that #module.metadata cannot — i.e.
    // information about how this platform surfaces the Module, not about
    // the Module itself. Flat shape after D11 removed presentation.operator
    // and D14 dropped the redundant `template` wrapper.
    presentation?: {
        description?: string
        category?:    string
        tags?:        [...string]
        examples?: [Name=string]: {
            description?: string
            values:       _
        }
    }

    metadata?: {
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }
}
```

## `#PlatformMatch`

Per-deploy match construct. The Go pipeline (or `opm-operator`) instantiates one `#PlatformMatch` per consumer `#Module` being deployed, walks the consumer's FQN demand against the platform's `#matchers`, and emits a render plan plus diagnostics.

```cue
// #PlatformMatch: Per-deploy walker. Resolves a consumer Module's FQN
// demand against #Platform.#matchers and surfaces matched / unmatched /
// ambiguous sets for the Go pipeline to act on.
#PlatformMatch: {
    platform!: #Platform
    module!:   #Module   // consumer Module being deployed

    // ---- Demand: FQNs the consumer Module reads ----
    //
    // 015 extends `_demand` with a `claims` sub-tree (module-level + per-
    // component) once #Claim instances exist on #Module.
    _demand: {
        resources: [FQN=string]: _
        resources: {
            if module.#components != _|_
            for _, c in module.#components
            if c.#resources != _|_
            for fqn, _ in c.#resources {
                (fqn): _
            }
        }

        traits: [FQN=string]: _
        traits: {
            if module.#components != _|_
            for _, c in module.#components
            if c.#traits != _|_
            for fqn, _ in c.#traits {
                (fqn): _
            }
        }
    }

    // ---- Lookup: candidate transformers per demanded FQN ----

    matched: {
        resources: [FQN=string]: [...#ComponentTransformer]
        resources: {
            for fqn, _ in _demand.resources
            if platform.#matchers.resources[fqn] != _|_ {
                (fqn): platform.#matchers.resources[fqn]
            }
        }

        traits: [FQN=string]: [...#ComponentTransformer]
        traits: {
            for fqn, _ in _demand.traits
            if platform.#matchers.traits[fqn] != _|_ {
                (fqn): platform.#matchers.traits[fqn]
            }
        }
    }

    // ---- Diagnostics ----
    //
    // FQNs the consumer demands but no transformer fulfils. D8 detection
    // signal. Response policy (fail / warn / drop) is platform-team
    // policy concern, deferred to 012.
    //
    // 015 adds `claims` to `matched`, `unmatched`, and `ambiguous` once
    // Claim demand exists on #Module.
    //
    // Membership tested against pre-built matched-FQN sets, not via
    // `matched.resources[fqn] == _|_` — that form errors with "undefined
    // field" under `cue vet -c` because `matched.resources` is typed
    // `[FQN]: [...#ComponentTransformer]`. (experiments/002 finding 5.)
    // List comprehensions yield via `{fqn}` — the trailing `fqn,` form is
    // invalid CUE (experiments/002 finding 1).
    unmatched: {
        let _matchedResourceSet = {
            for fqn, _ in matched.resources {(fqn): _}
        }
        let _matchedTraitSet = {
            for fqn, _ in matched.traits {(fqn): _}
        }
        resources: [
            for fqn, _ in _demand.resources
            if _matchedResourceSet[fqn] == _|_ {fqn},
        ]
        traits: [
            for fqn, _ in _demand.traits
            if _matchedTraitSet[fqn] == _|_ {fqn},
        ]
    }

    // FQNs with > 1 candidate. With multi-fulfiller forbidden at the
    // platform level (D13), this should always be empty when reached —
    // the platform-eval would have already failed. Kept as a diagnostic
    // surface in case a future enhancement reopens multi-fulfiller.
    ambiguous: {
        resources: {
            for fqn, ts in matched.resources
            if len(ts) > 1 {
                (fqn): ts
            }
        }
        traits: {
            for fqn, ts in matched.traits
            if len(ts) > 1 {
                (fqn): ts
            }
        }
    }
}
```

## `#ComponentTransformer`

Sole transformer primitive at this layer (D17). Fires once per matching `#Component`. See [`05-component-transformer-and-matcher.md`](05-component-transformer-and-matcher.md) for the full design narrative, runtime guarantee (D18), matcher algorithm, and worked example.

```cue
// catalog/core/v1alpha2/transformer.cue
package v1alpha2

#ComponentTransformer: {
    apiVersion: "opmodel.dev/core/v1alpha2"
    kind:       "ComponentTransformer"

    metadata: {
        modulePath!: #ModulePathType
        version!:    #MajorVersionType
        name!:       #NameType
        #definitionName: (#KebabToPascal & {"in": name}).out
        fqn: #FQNType & "\(modulePath)/\(name)@\(version)"
        description!: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Match keys — read against the candidate #Component.
    // 015 extends this set with requiredClaims / optionalClaims for
    // component-level Claim fulfilment.
    requiredLabels?:    #LabelsAnnotationsType
    optionalLabels?:    #LabelsAnnotationsType
    requiredResources?: [FQN=string]: _
    optionalResources?: [FQN=string]: _
    requiredTraits?:    [FQN=string]: _
    optionalTraits?:    [FQN=string]: _

    readsContext?:  [...string]
    producesKinds?: [...string]

    // Runtime always supplies both inputs concretely (D18).
    #transform: {
        #moduleRelease: _
        #component:     _
        #context:       #TransformerContext

        output: {...}
    }
}

// 015 widens this to `#ComponentTransformer | #ModuleTransformer`.
#TransformerMap: [#FQNType]: #ComponentTransformer
```

## Field Documentation

### `#Platform`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `apiVersion` | `"opmodel.dev/core/v1alpha2"` | fixed | OPM core |
| `kind` | `"Platform"` | fixed | Always `"Platform"` |
| `metadata.name` | `#NameType` | yes | Platform identifier (kebab-case) |
| `metadata.description` | `string` | no | Human-readable summary |
| `type` | `string` | yes | Target type (`"kubernetes"`, future: `"docker-compose"`, etc.) |
| `#ctx` | `#PlatformContext` | yes | Platform-level context (016) |
| `#registry` | `[Id=#NameType]: #ModuleRegistration` | yes | Registered Modules (static + runtime). Id MUST be kebab-case (D16). Runtime entries are FillPath-injected by `opm-operator` from `ModuleRelease` CRs (D11). Static + runtime writes to the same Id unify via CUE; concrete-value disagreement = `_\|_` surfaced by reconciler (D15). |
| `#knownResources` | `[FQN=string]: #Resource` | computed | Resource types from `#registry[*].#module.#defines.resources` (only entries where `enabled: true` per D14). |
| `#knownTraits` | `[FQN=string]: #Trait` | computed | Trait types from enabled `#registry[*].#module.#defines.traits`. |
| `#composedTransformers` | `#TransformerMap` | computed | All transformers from enabled `#registry[*].#module.#defines.transformers`, keyed by FQN. Value type is `[FQN]: #ComponentTransformer` at this layer; 015 widens to `#ComponentTransformer \| #ModuleTransformer`. Capability fulfilment for Resources/Traits is registered via the transformer's `requiredResources` / `requiredTraits` fields (D7). |
| `#matchers.resources` | `[FQN=string]: [...#ComponentTransformer]` | computed | Reverse index: per-Resource-FQN, transformer candidates whose `requiredResources` includes that FQN (D12). |
| `#matchers.traits` | `[FQN=string]: [...#ComponentTransformer]` | computed | Same shape, keyed off `requiredTraits`. |
| `#matchers._invalid` | `{resources: [...string], traits: [...string]}` | computed | FQNs with > 1 fulfiller. Hidden diagnostic. Paired with `_noMultiFulfiller` constraint that forces `_\|_` when any sub-list is non-empty (D13). 015 adds a `claims` sub-list. |

### `#ModuleRegistration`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `#module` | `#Module` | yes | Registered Module value (CUE-imported or runtime-injected) |
| `enabled` | `bool` | default `true` | When false, hides every projection of this entry from the platform (`#knownResources`, `#knownTraits`, `#composedTransformers`, `#matchers` — and `#knownClaims` once 015 lands) — D14 |
| `presentation` | `{description?, category?, tags?, examples?}` | no | Self-service catalog curation metadata. Flat shape after D11/D14. |
| `metadata.labels` | `#LabelsAnnotationsType` | no | Registration labels |
| `metadata.annotations` | `#LabelsAnnotationsType` | no | Registration annotations |

### `#PlatformMatch`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `platform` | `#Platform` | yes | Platform whose `#matchers` index is consulted |
| `module` | `#Module` | yes | Consumer Module being deployed |
| `matched.resources` | `[FQN=string]: [...#ComponentTransformer]` | computed | Per-FQN candidate list for Resource demand |
| `matched.traits` | `[FQN=string]: [...#ComponentTransformer]` | computed | Per-FQN candidate list for Trait demand |
| `unmatched.{resources,traits}` | `[...string]` | computed | FQNs the consumer demands with zero fulfillers (D8). 015 adds `claims`. |
| `ambiguous.{resources,traits}` | `[FQN=string]: [...transformer]` | computed | FQNs with > 1 fulfiller (closed by D13 — should always be empty at runtime). 015 adds `claims`. |

### `#ComponentTransformer`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `apiVersion` | `"opmodel.dev/core/v1alpha2"` | fixed | OPM core |
| `kind` | `"ComponentTransformer"` | fixed | Always `"ComponentTransformer"` |
| `metadata.modulePath` | `#ModulePathType` | yes | Module path (e.g. `"opmodel.dev/opm/v1alpha2/providers/kubernetes"`) |
| `metadata.version` | `#MajorVersionType` | yes | Major version |
| `metadata.name` | `#NameType` | yes | Transformer name (kebab-case) |
| `metadata.fqn` | `#FQNType` | computed | `\(modulePath)/\(name)@\(version)` — used as `#defines.transformers` map key |
| `metadata.description` | `string` | yes | Human-readable summary |
| `requiredLabels` / `optionalLabels` | `#LabelsAnnotationsType` | no | Component label match keys |
| `requiredResources` / `optionalResources` | `[FQN=string]: _` | no | Component `#resources` FQN match keys |
| `requiredTraits` / `optionalTraits` | `[FQN=string]: _` | no | Component `#traits` FQN match keys. 015 adds `requiredClaims` / `optionalClaims`. |
| `readsContext` | `[...string]` | no | Declarative `#ctx` paths the body reads (catalog-UI hint) |
| `producesKinds` | `[...string]` | no | Output Kubernetes kinds (catalog-UI hint) |
| `#transform` | `{ #moduleRelease, #component, #context, output }` | yes | Render function. Runtime supplies all three inputs concretely (D18). |

## File Locations

### New files

| Path | Purpose |
|------|---------|
| `catalog/core/v1alpha2/platform.cue` | `#Platform`, `#ModuleRegistration`, `#PlatformMatch` |
| `catalog/core/v1alpha2/transformer.cue` | `#ComponentTransformer`, `#TransformerMap`. 015 extends with `#ModuleTransformer` and widens `#TransformerMap` to the union. |
| `catalog/experiments/002-platform-construct/` | Self-contained CUE harness exercising every schema in this doc — mirrors `experiments/001-module-context/`. Validates D3 (FQN collision), D13 (multi-fulfiller forbidden), D14 (enabled hides), D15 (concurrent-write conflict), D16 (kebab Id), the `#PlatformMatch.unmatched` walker, and basic `#known*` / `#composedTransformers` / `#matchers` projections. |

### Removed / superseded

| Path | Status |
|------|--------|
| `#Platform` definition sketched in `enhancements/archive/008-platform-construct/03-schema.md` | Superseded by this enhancement; 008's `#Provider` composition (`#providers` field, `#composedTransformers` from list, ordered priority semantics) is no longer applicable. |
| `catalog/core/v1alpha2/provider.cue` | `#Provider` retired in this enhancement (D4 superseded). Matcher migrates to consume `#composedTransformers` + `#matchers` directly. The file is deleted; any remaining imports are repointed at the new constructs. |

### Defined elsewhere (referenced from this enhancement)

| Path | Purpose | Owning enhancement |
|------|---------|--------------------|
| `catalog/core/v1alpha2/context.cue` | `#PlatformContext`, `#EnvironmentContext`, `#ModuleContext`, `#RuntimeContext`, `#ComponentNames` | 016 |
| `catalog/core/v1alpha2/environment.cue` | `#Environment` | 016 |
| `catalog/core/v1alpha2/context_builder.cue` | `#ContextBuilder` | 016 |
| `catalog/core/v1alpha2/module.cue` | `#Module` flat shape (eight slots) | 015 |
| `catalog/core/v1alpha2/claim.cue` | `#Claim` primitive, `#ClaimMap` | 015 |
| `catalog/core/v1alpha2/transformer.cue` | `#ModuleTransformer` (extends this enhancement's transformer file) | 015 |

> Flat-package note: 014 / 015 / 016 all live in the single `v1alpha2` package, so `#Platform`'s schema references `#ComponentTransformer` and `#TransformerMap` (and 015's `#ModuleTransformer`) directly without a cross-package import alias.
