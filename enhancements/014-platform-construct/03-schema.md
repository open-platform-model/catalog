# Schema — `#Platform` Construct

## Summary

Three CUE definitions land in `core/v1alpha2`:

- `#Platform` — `core/v1alpha2/platform.cue` (replaces 008's `#Platform` schema)
- `#ModuleRegistration` — same file
- `#PlatformMatch` — same file (per-deploy match construct)

All depend on the flat `#Module` shape with `#defines` from enhancement 015 and the two transformer primitives from 015 TR-D5.

## `#Platform`

```cue
package v1alpha2

import (
    transformer "opmodel.dev/core/v1alpha2:transformer"
)

// #Platform: A deployment target's identity, context, and registered
// extensions. Composition unit is #Module (registered via #registry).
// All outward views are computed projections over #registry.
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
    #registry: [Id=string]: #ModuleRegistration

    // ---- Computed views over #registry ----

    // Catalog views — type definitions published by registered Modules.
    // Each is keyed by FQN. FQN collisions across Modules surface as CUE
    // unification errors (correct behaviour — forces conflict resolution
    // at registration time).
    #knownResources: [FQN=string]: #Resource & {
        for _, reg in #registry
        if reg.enabled
        if reg.#module.#defines != _|_
        if reg.#module.#defines.resources != _|_
        for fqn, v in reg.#module.#defines.resources {
            (fqn): v
        }
    }

    #knownTraits: [FQN=string]: #Trait & {
        for _, reg in #registry
        if reg.enabled
        if reg.#module.#defines != _|_
        if reg.#module.#defines.traits != _|_
        for fqn, v in reg.#module.#defines.traits {
            (fqn): v
        }
    }

    #knownClaims: [FQN=string]: #Claim & {
        for _, reg in #registry
        if reg.enabled
        if reg.#module.#defines != _|_
        if reg.#module.#defines.claims != _|_
        for fqn, v in reg.#module.#defines.claims {
            (fqn): v
        }
    }

    // Active rendering registry — all transformers from all enabled Modules.
    // Capability fulfilment is registered implicitly: any transformer
    // (#ComponentTransformer or #ModuleTransformer) whose requiredClaims
    // includes a Claim FQN is the supply registration for that Claim
    // (see 015 TR-D5). No separate #apis aggregation map exists;
    // multi-fulfiller resolution is left to the matcher and to a future
    // enhancement (see OQ5).
    #composedTransformers: transformer.#TransformerMap & {
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
    // time = unmatched (D8). Multi-candidate = ambiguous (OQ5).
    //
    // Resources and Traits are component-scope only (CL-D11); only
    // #ComponentTransformer can fulfil them. Claims may be fulfilled by
    // either #ComponentTransformer (component-level Claims) or
    // #ModuleTransformer (module-level Claims) per 015 TR-D5.
    #matchers: {
        // Universe of FQNs any transformer demands, used to drive the
        // outer comprehensions. Hidden — implementation detail.
        let _resourceFqns = {
            for _, t in #composedTransformers
            if t.kind == "ComponentTransformer"
            if t.requiredResources != _|_
            for fqn, _ in t.requiredResources {
                (fqn): null
            }
        }
        let _traitFqns = {
            for _, t in #composedTransformers
            if t.kind == "ComponentTransformer"
            if t.requiredTraits != _|_
            for fqn, _ in t.requiredTraits {
                (fqn): null
            }
        }
        let _claimFqns = {
            for _, t in #composedTransformers
            if t.requiredClaims != _|_
            for fqn, _ in t.requiredClaims {
                (fqn): null
            }
        }

        resources: [FQN=string]: [...transformer.#ComponentTransformer]
        resources: {
            for fqn, _ in _resourceFqns {
                (fqn): [
                    for _, t in #composedTransformers
                    if t.kind == "ComponentTransformer"
                    if t.requiredResources != _|_
                    if t.requiredResources[fqn] != _|_
                    t,
                ]
            }
        }

        traits: [FQN=string]: [...transformer.#ComponentTransformer]
        traits: {
            for fqn, _ in _traitFqns {
                (fqn): [
                    for _, t in #composedTransformers
                    if t.kind == "ComponentTransformer"
                    if t.requiredTraits != _|_
                    if t.requiredTraits[fqn] != _|_
                    t,
                ]
            }
        }

        claims: [FQN=string]: [...(transformer.#ComponentTransformer | transformer.#ModuleTransformer)]
        claims: {
            for fqn, _ in _claimFqns {
                (fqn): [
                    for _, t in #composedTransformers
                    if t.requiredClaims != _|_
                    if t.requiredClaims[fqn] != _|_
                    t,
                ]
            }
        }
    }
}
```

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
    // Useful for "import types but skip transformer composition" cases.
    enabled: bool | *true

    // Optional self-service catalog metadata. Carries platform-curation
    // data (category/tags/examples) that #module.metadata cannot — i.e.
    // information about how this platform surfaces the Module, not about
    // the Module itself.
    presentation?: template?: {
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

#PlatformMap: [string]: #Platform
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

    _demand: {
        resources: [FQN=string]: null
        resources: {
            for _, c in module.#components
            if c.#resources != _|_
            for fqn, _ in c.#resources {
                (fqn): null
            }
        }

        traits: [FQN=string]: null
        traits: {
            for _, c in module.#components
            if c.#traits != _|_
            for fqn, _ in c.#traits {
                (fqn): null
            }
        }

        // Module-level vs component-level Claims — kept separate because
        // they map to different transformer kinds (TR-D5).
        claims: {
            module: [FQN=string]: null
            module: {
                if module.#claims != _|_
                for fqn, _ in module.#claims {
                    (fqn): null
                }
            }
            component: [FQN=string]: null
            component: {
                for _, c in module.#components
                if c.#claims != _|_
                for fqn, _ in c.#claims {
                    (fqn): null
                }
            }
        }
    }

    // ---- Lookup: candidate transformers per demanded FQN ----

    matched: {
        resources: [FQN=string]: [...transformer.#ComponentTransformer]
        resources: {
            for fqn, _ in _demand.resources
            if platform.#matchers.resources[fqn] != _|_ {
                (fqn): platform.#matchers.resources[fqn]
            }
        }

        traits: [FQN=string]: [...transformer.#ComponentTransformer]
        traits: {
            for fqn, _ in _demand.traits
            if platform.#matchers.traits[fqn] != _|_ {
                (fqn): platform.#matchers.traits[fqn]
            }
        }

        claims: [FQN=string]: [...(transformer.#ComponentTransformer | transformer.#ModuleTransformer)]
        claims: {
            for fqn, _ in _demand.claims.module
            if platform.#matchers.claims[fqn] != _|_ {
                (fqn): platform.#matchers.claims[fqn]
            }
            for fqn, _ in _demand.claims.component
            if platform.#matchers.claims[fqn] != _|_ {
                (fqn): platform.#matchers.claims[fqn]
            }
        }
    }

    // ---- Diagnostics ----

    // FQNs the consumer demands but no transformer fulfils. D8 detection
    // signal. Response policy (fail / warn / drop) is platform-team
    // policy concern, deferred to 012.
    unmatched: {
        resources: [
            for fqn, _ in _demand.resources
            if matched.resources[fqn] == _|_ || len(matched.resources[fqn]) == 0
            fqn,
        ]
        traits: [
            for fqn, _ in _demand.traits
            if matched.traits[fqn] == _|_ || len(matched.traits[fqn]) == 0
            fqn,
        ]
        claims: [
            for fqn, _ in (_demand.claims.module & _demand.claims.component)
            if matched.claims[fqn] == _|_ || len(matched.claims[fqn]) == 0
            fqn,
        ]
    }

    // FQNs with > 1 candidate. Resolution policy deferred (OQ5).
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
        claims: {
            for fqn, ts in matched.claims
            if len(ts) > 1 {
                (fqn): ts
            }
        }
    }
}
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
| `#registry` | `[Id=string]: #ModuleRegistration` | yes | Registered Modules (static + runtime). Runtime entries are FillPath-injected by `opm-operator` from `ModuleRelease` CRs (D11). |
| `#knownResources` | `[FQN=string]: #Resource` | computed | Resource types from `#registry[*].#module.#defines.resources` |
| `#knownTraits` | `[FQN=string]: #Trait` | computed | Trait types from `#registry[*].#module.#defines.traits` |
| `#knownClaims` | `[FQN=string]: #Claim` | computed | Claim types from `#registry[*].#module.#defines.claims` |
| `#composedTransformers` | `transformer.#TransformerMap` | computed | All transformers (`#ComponentTransformer \| #ModuleTransformer`), keyed by FQN. Capability fulfilment is registered via each transformer's `requiredClaims` field (see 015 TR-D5). |
| `#matchers.resources` | `[FQN=string]: [...#ComponentTransformer]` | computed | Reverse index: per-Resource-FQN, transformer candidates whose `requiredResources` includes that FQN (D12). |
| `#matchers.traits` | `[FQN=string]: [...#ComponentTransformer]` | computed | Same shape, keyed off `requiredTraits`. |
| `#matchers.claims` | `[FQN=string]: [...(#ComponentTransformer \| #ModuleTransformer)]` | computed | Same shape, keyed off `requiredClaims`; spans both transformer kinds. |

### `#ModuleRegistration`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `#module` | `#Module` | yes | Registered Module value (CUE-imported or runtime-injected) |
| `enabled` | `bool` | default `true` | Disable without removal |
| `presentation.template` | `{...}` | no | Self-service catalog curation metadata (category, tags, examples). Optional. |
| `metadata.labels` | `#LabelsAnnotationsType` | no | Registration labels |
| `metadata.annotations` | `#LabelsAnnotationsType` | no | Registration annotations |

### `#PlatformMatch`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `platform` | `#Platform` | yes | Platform whose `#matchers` index is consulted |
| `module` | `#Module` | yes | Consumer Module being deployed |
| `matched.resources` | `[FQN=string]: [...#ComponentTransformer]` | computed | Per-FQN candidate list for Resource demand |
| `matched.traits` | `[FQN=string]: [...#ComponentTransformer]` | computed | Per-FQN candidate list for Trait demand |
| `matched.claims` | `[FQN=string]: [...(#ComponentTransformer \| #ModuleTransformer)]` | computed | Per-FQN candidate list for Claim demand (module-level + component-level) |
| `unmatched.{resources,traits,claims}` | `[...string]` | computed | FQNs the consumer demands with zero fulfillers (D8) |
| `ambiguous.{resources,traits,claims}` | `[FQN=string]: [...transformer]` | computed | FQNs with > 1 fulfiller (OQ5) |

## File Locations

### New files

| Path | Purpose |
|------|---------|
| `catalog/core/v1alpha2/platform.cue` | `#Platform`, `#ModuleRegistration`, `#PlatformMatch`, `#PlatformMap` |

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
| `catalog/core/v1alpha2/transformer.cue` | `#ComponentTransformer`, `#ModuleTransformer`, `#TransformerMap` | 015 |
