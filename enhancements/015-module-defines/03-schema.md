# Schema — `#Module` Flat Shape with `#Claim` Primitive and `#defines` Channel

This file is the CUE-level reference: type definitions, field tables, file locations. Design rationale, examples, supersession history, and decisions live in the topical narrative files (see [`02-design.md`](02-design.md) for the index).

## File Locations

```text
catalog/core/v1alpha2/
├── module.cue          // #Module (modified — eight slots, #defines, #ctx)
├── claim.cue           // #Claim (new primitive)
└── transformer.cue     // #ComponentTransformer + #ModuleTransformer (replaces v1alpha1 #Transformer)
```

Concrete commodity Claim definitions ship under `catalog/opm/v1alpha2/claims/`; vendor specialty Claims ship in their own packages. See [`06-claim-primitive.md`](06-claim-primitive.md) for the triplet / quartet pattern (and a worked `#ManagedDatabaseClaim` definition).

## `#Claim` (primitive)

```cue
package v1alpha2

// #Claim: Defines the shape of an ecosystem-supplied need.
// The same primitive serves as both the type definition (when authored in
// a catalog or vendor package) and the request (when used in a Module's
// #claims). Identity is the metadata FQN — there is no string type field.
//
// apiVersion is left open so concrete Claim definitions (e.g.
// #ManagedDatabaseClaim) set their own apiVersion. The base #Claim does
// not pin one.
#Claim: {
    apiVersion!: string                          // open — set by concrete claim
    kind:        "Claim"

    metadata: {
        modulePath!: #ModulePathType              // "opmodel.dev/opm/v1alpha2/claims/data"
        version!:    #MajorVersionType            // "v1"
        name!:       #NameType                    // "managed-database"
        #definitionName: (#KebabToPascal & {"in": name}).out

        fqn: #FQNType & "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // MUST be an OpenAPIv3 compatible schema.
    // The field name is the camelCase of metadata.name (kebab-case names
    // are converted: "managed-database" => "managedDatabase").
    #spec!: ((#KebabToCamel & {"in": metadata.name}).out): _

    // Open shape — concrete Claim definitions pin their own #status schema.
    // Populated by the fulfilling transformer at deploy time.
    // Module authors read via #claims.<id>.#status.<field>.
    #status?: _
}

#ClaimMap: [string]: _
```

`#Claim` lives in the flat `v1alpha2` package alongside `#Resource`, `#Trait`, `#Blueprint`. Helper types (`#ModulePathType`, `#MajorVersionType`, `#NameType`, `#FQNType`, `#KebabToPascal`, `#KebabToCamel`, `#LabelsAnnotationsType`) all live in the same package — no `t.` prefix needed.

The `#status?` channel and its writeback semantics are documented in [`06-claim-primitive.md`](06-claim-primitive.md) and [`07-transformer-redesign.md`](07-transformer-redesign.md).

## Two transformer primitives

`#ComponentTransformer` (per-component fan-out) and `#ModuleTransformer` (per-module fan-out) replace the v1alpha1 single `#Transformer`. Both ship through `#Module.#defines.transformers` (slot type: union `#ComponentTransformer | #ModuleTransformer`). CRD installation continues to live in `#components` via `#CRDsResource` — unchanged.

**Canonical schema, runtime guarantees, matcher pseudocode, status writeback channel, and worked examples live in [`07-transformer-redesign.md`](07-transformer-redesign.md).** This doc does not duplicate them.

## Updated `#Module`

```cue
package v1alpha2

import (
    cue_uuid "uuid"
    transformer "opmodel.dev/core/v1alpha2:transformer"
)

// #Module: The portable application/API/operator blueprint created by
// developers, vendors, or platform teams.
#Module: {
    apiVersion: "opmodel.dev/core/v1alpha2"
    kind:       "Module"

    metadata: {
        modulePath!: #ModulePathType
        name!:       #NameType
        version!:    #VersionType
        fqn:         #ModuleFQNType & "\(modulePath)/\(name):\(version)"
        uuid:        #UUIDType & cue_uuid.SHA1(OPMNamespace, fqn)
        #definitionName: (#KebabToPascal & {"in": name}).out

        defaultNamespace?: string
        description?:      string
        labels?:           #LabelsAnnotationsType
        annotations?:      #LabelsAnnotationsType

        labels: {
            "module.opmodel.dev/name":    "\(name)"
            "module.opmodel.dev/version": "\(version)"
            "module.opmodel.dev/uuid":    "\(uuid)"
        }
    }

    // Nucleus
    #config:     _
    debugValues: _

    // Runtime-injected counterpart to #config. Computed by #ContextBuilder
    // (enhancement 016) and unified into the module by #ModuleRelease before
    // components evaluate. Module authors read it inside #components but
    // never assign it directly. Schema: #ModuleContext.
    #ctx: #ModuleContext

    #components: [Id=string]: #Component & {
        metadata: {
            name: string | *Id
            labels: "component.opmodel.dev/name": name
        }
    }

    // Inward — operate on the module itself.
    // (#policies omitted from v1alpha2 entirely — MS-D4. Policy redesign in 012.)
    #lifecycles?: [Id=string]: #Lifecycle
    #workflows?:  [Id=string]: #Workflow

    // Outward — instances visible to the platform and other modules
    #claims?: [Id=string]: #Claim

    // Outward — publication channel.
    // Type definitions and rendering extensions this Module ships to the
    // ecosystem. Keyed by FQN. Map key MUST equal value.metadata.fqn —
    // CUE unification enforces this via the inline & {metadata: fqn: FQN}
    // constraint on each sub-map.
    #defines?: {
        resources?:    [FQN=string]: #Resource  & {metadata: fqn: FQN}
        traits?:       [FQN=string]: #Trait     & {metadata: fqn: FQN}
        claims?:       [FQN=string]: #Claim     & {metadata: fqn: FQN}
        transformers?: [FQN=string]: (transformer.#ComponentTransformer | transformer.#ModuleTransformer) & {metadata: fqn: FQN}
    }
}

#ModuleMap: [string]: #Module
```

`v1alpha2`'s flat package layout means `#Component`, `#Resource`, `#Trait`, `#Blueprint`, `#Claim`, `#ModuleContext`, `#Lifecycle`, `#Workflow`, and the helper types are all unprefixed inside the package. `#Transformer` lives in the sibling `transformer` package and is the only cross-package import.

The eight-slot rationale, the supersession history (drop `#policies`, drop `#apis`), and the no-`#requires` decision live in [`04-module-shape.md`](04-module-shape.md). The `#defines` shape and FQN-binding rule live in [`05-defines-channel.md`](05-defines-channel.md).

## Field Documentation

### `#Claim`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `apiVersion` | `string` | yes | Open string set by concrete Claim definitions (e.g. `opmodel.dev/opm/v1alpha2`, `vendor.com/x/v1alpha2`) |
| `kind` | `"Claim"` | fixed | Always `"Claim"` |
| `metadata.modulePath` | `#ModulePathType` | yes | CUE module path the Claim definition lives in |
| `metadata.version` | `#MajorVersionType` | yes | Major version of the Claim definition |
| `metadata.name` | `#NameType` | yes | Kebab-case name of the Claim |
| `metadata.fqn` | `#FQNType` | computed | `\(modulePath)/\(name)@\(version)` — the deploy-time identity |
| `metadata.description` | `string` | no | Human-readable summary |
| `#spec` | `_` (camelCase field name from `metadata.name`) | yes | OpenAPIv3 schema for the request |
| `#status` | `_` (open; pinned by concrete Claims) | no | Resolution data written by the fulfilling transformer at deploy time. Open on the base; concrete Claims (e.g. `#ManagedDatabaseClaim`) pin a `#status` schema. Empty when fulfilment is side-effect only. |

### `#ComponentTransformer` — fields (v1alpha2)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `kind` | `"ComponentTransformer"` | fixed | Type identity — matcher dispatches per-component fan-out |
| `requiredLabels` | `#LabelsAnnotationsType` | no | Component MUST have these labels |
| `optionalLabels` | `#LabelsAnnotationsType` | no | Component MAY have these labels |
| `requiredResources` | `[FQN=string]: _` | no | Component MUST include these `#Resource` types |
| `optionalResources` | `[FQN=string]: _` | no | Component MAY include these |
| `requiredTraits` | `[FQN=string]: _` | no | Component MUST include these `#Trait` types |
| `optionalTraits` | `[FQN=string]: _` | no | Component MAY include these |
| `requiredClaims` | `[FQN=string]: _` | no | Component-level Claims the transformer fulfils |
| `optionalClaims` | `[FQN=string]: _` | no | Optional component-level Claim FQNs |
| `readsContext` | `[...string]` | no | Declarative list of `#ctx` paths the render reads |
| `producesKinds` | `[...string]` | no | Declarative list of output kinds |
| `#transform.#moduleRelease` | `_` | yes | Fully concrete `#ModuleRelease` — runtime always supplies this |
| `#transform.#component` | `_` | yes | The matched `#Component` (singular) |
| `#transform.#context` | `#TransformerContext` | yes | Inherited labels/annotations + runtime identity |
| `#transform.output` | `{...}` | yes | Provider-specific output |

### `#ModuleTransformer` — fields (v1alpha2)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `kind` | `"ModuleTransformer"` | fixed | Type identity — matcher dispatches per-module fan-out |
| `requiredLabels` | `#LabelsAnnotationsType` | no | Module MUST have these labels |
| `optionalLabels` | `#LabelsAnnotationsType` | no | Module MAY have these labels |
| `requiredClaims` | `[FQN=string]: _` | no | Module-level Claims the transformer fulfils |
| `optionalClaims` | `[FQN=string]: _` | no | Optional module-level Claim FQNs |
| `requiresComponents.resources` | `[FQN=string]: _` | no | Pre-fire gate: at least one component MUST carry these resources |
| `requiresComponents.traits` | `[FQN=string]: _` | no | Pre-fire gate: at least one component MUST carry these traits |
| `requiresComponents.claims` | `[FQN=string]: _` | no | Pre-fire gate: at least one component MUST carry these component-level claims |
| `readsContext` | `[...string]` | no | Declarative list of `#ctx` paths the render reads |
| `producesKinds` | `[...string]` | no | Declarative list of output kinds |
| `#transform.#moduleRelease` | `_` | yes | Fully concrete `#ModuleRelease` — body iterates `#components` itself when needed |
| `#transform.#context` | `#TransformerContext` | yes | Inherited labels/annotations + runtime identity |
| `#transform.output` | `{...}` | yes | Provider-specific output (typically a struct keyed by intent) |

### `#Module` — added/changed slots

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `#lifecycles` | `[Id=string]: #Lifecycle` | no | Inward — state transitions |
| `#workflows` | `[Id=string]: #Workflow` | no | Inward — on-demand operations |
| `#claims` | `[Id=string]: #Claim` | no | Outward — module-level needs (instances) |
| `#defines.resources` | `[FQN=string]: #Resource` | no | Outward — Resource type definitions published, FQN-keyed |
| `#defines.traits` | `[FQN=string]: #Trait` | no | Outward — Trait type definitions published, FQN-keyed |
| `#defines.claims` | `[FQN=string]: #Claim` | no | Outward — Claim type definitions published, FQN-keyed |
| `#defines.transformers` | `[FQN=string]: #ComponentTransformer \| #ModuleTransformer` | no | Outward — Transformer values published, FQN-keyed |

### `#defines` placement vs instance slots

`#Claim` is the primitive most affected by `#defines`. The same primitive serves three roles, distinguished by placement (see [`05-defines-channel.md`](05-defines-channel.md) for the full table and [`06-claim-primitive.md`](06-claim-primitive.md) for the consumer-side mechanics):

| Placement | Role |
|-----------|------|
| `#defines.claims["fqn"]: #Claim` | Module **publishes** this Claim type (catalog vocabulary) |
| `#claims.id: #Claim & {#spec: ...}` (component or module level) | Module **requests** an instance (demand) |
| `#defines.transformers["fqn"]: #ComponentTransformer & {requiredClaims …}` (component-level) or `#ModuleTransformer & {requiredClaims …}` (module-level) | Module **fulfils** this Claim type (supply, via the transformer's match keys) |

`#Resource` and `#Trait` types are publishable through `#defines`; instances of `#Resource` and `#Trait` continue to live inside `#Component` (component-internal). `#Blueprint` is **not** publishable through `#defines` (DEF-D6) — it is a CUE composition consumed by Components via direct package import, with no platform-level aggregation.

`#defines.transformers` is the only outward home for transformer values. `#PolicyTransformer` is excluded from this enhancement — see DEF-D5 in [`10-decisions.md`](10-decisions.md) and the policy redesign (012).
