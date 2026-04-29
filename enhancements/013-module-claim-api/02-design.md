# Design — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

## Design Goals

- Keep `#Module` a single type that covers Applications, API descriptions, and Operators uniformly.
- Bound `#Module`'s top-level field set to a fixed, predictable list. New ecosystem primitives must not require `#Module` schema changes.
- Provide a primitive surface for ecosystem-extensible needs (`#Claim`) and provided capabilities (`#Api`) that vendors can extend without catalog changes.
- Preserve the App/API duality via `#config` and make Operator Modules a natural fit (controller + claims-as-needs + claims-fulfilled-via-apis).
- Sharpen the litmus test so that `#Resource` and `#Claim` answer distinct questions and authors can pick the right primitive without reading source.

## Non-Goals

- Splitting `#Module` into kind-discriminated variants (`#AppModule`, `#APIModule`, `#OperatorModule`).
- Defining the deploy-time runtime that matches `#claim`s to `#api`s. This design specifies declarative shape only; the platform runtime is free to populate a self-service catalog, a deploy-time match cache, both, or anything equivalent.
- CRD installation semantics. CRDs continue to deploy via `#CRDsResource` inside `#components`. `#Api` carries no CRD installation logic.
- Migration tooling. Existing `#Module`s using `#policies` must still validate; migration is addressed in a follow-up.
- Resolving the cross-component noun grammar from enhancement 012 in full. This enhancement provides the noun answer at module/component scope; module-spanning shared nouns (mesh tenant, identity domain) may still need 012's work.

## High-Level Approach

`#Module` becomes a flat struct with nine slots in three groups:

```text
nucleus       metadata        # identity
              #config         # parameter / API schema
              debugValues     # example concrete values
              #components     # body — what is built

inward        #policies       # rules + directives (governance + operational orchestration)
              #lifecycles     # state transitions for the module / its components
              #workflows      # on-demand operations

outward       #claims         # ecosystem-supplied needs (data-plane and platform-relationship)
              #apis           # ecosystem-supplied capabilities this module registers
```

`#Action` is **not** a top-level Module slot; it is a primitive consumed by `#Lifecycle` and `#Workflow` constructs.

`#Claim` and `#Api` are new primitives. `#Claim` defines the shape of a need; the same primitive serves as both type definition (in catalog or vendor packages) and request (in `#claims`). `#Api` registers a Module's capability by embedding a `#Claim` as its `schema`. Identity is structural: matching is by CUE definition reference plus an `apiVersion` + path FQN that travels across module boundaries.

`#Resource` and `#Claim` differ on a sharp axis: `#Resource` is **catalog-fixed and transformer-rendered**; `#Claim` is **ecosystem-extended and provider-fulfilled**. The litmus is updated accordingly.

`#Claim` may be placed at component-level (data-plane needs — DB, queue, cache) or at module-level (platform-relationship needs — DNS, tenant admission, identity, observability backend, mesh membership). `#Resource` stays component-level only.

## Schema / API Surface

### `#Module` — flat shape

```cue
#Module: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Module"

    metadata:    {...}                         // unchanged
    #config:     _                              // parameter / API schema
    debugValues: _                              // example concrete values

    #components:  [Id=string]: component.#Component

    #policies?:   [Id=string]: policy.#Policy
    #lifecycles?: [Id=string]: lifecycle.#Lifecycle
    #workflows?:  [Id=string]: workflow.#Workflow

    #claims?:     [Id=string]: claim.#Claim
    #apis?:       [Id=string]: api.#Api
}
```

Nine top-level fields. Five are optional. A bare app fills four. An operator Module fills six or seven.

### `#Claim` — primitive

Lives in `catalog/core/v1alpha1/primitives/claim.cue`. Shape mirrors `#Directive` (apiVersion + metadata + `#spec`), with `apiVersion` left **open** so concrete Claim definitions set their own.

```cue
#Claim: {
    apiVersion!: string                          // open — set by concrete claim
    kind:        "Claim"

    metadata: {
        modulePath!: t.#ModulePathType            // "opmodel.dev/opm/v1alpha1/claims/data"
        version!:    t.#MajorVersionType          // "v1"
        name!:       t.#NameType                  // "managed-database"
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    #spec!: ((t.#KebabToCamel & {"in": metadata.name}).out): _
}
```

### `#Api` — primitive

Lives in `catalog/core/v1alpha1/primitives/api.cue`. `#Api` embeds exactly one `#Claim` (1:1) and carries optional self-service catalog metadata.

```cue
#Api: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Api"

    schema!: claim.#Claim                       // embed via CUE — commodity import or specialty

    metadata?: {
        description?: string
        examples?:    _
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }
}
```

`#Api` does **not** carry CRD installation logic. Operators continue to ship CRDs via `#CRDsResource` inside `#components`.

### Concrete Claim definition triplet

Concrete Claims follow the existing Resource triplet pattern (`#X` schema + `#XDefaults` defaults + `#XClaim` wrapper). Lives in catalog packages (well-known commodities) or vendor packages (specialties).

```cue
// catalog/opm/v1alpha1/claims/data/managed_database.cue
package data

#ManagedDatabase: {
    engine!:  "postgres" | "mysql" | "mongodb"
    version!: string
    sizeGB!:  int & >0
}

#ManagedDatabaseDefaults: {
    engine: "postgres"
    sizeGB: 10
}

#ManagedDatabaseClaim: claim.#Claim & {
    apiVersion: "opmodel.dev/opm/v1alpha1"
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/data"
        version:    "v1"
        name:       "managed-database"
        description: "Well-known commodity contract for a managed relational database."
    }
    #spec: managedDatabase: #ManagedDatabase
}
```

### Matching

Identity travels through two layers:

- **CUE-level (authoring time):** A Module's `#claims` references a `#Claim` definition (e.g. `data.#ManagedDatabaseClaim`). An `#Api`'s `schema` field embeds the same definition. CUE unification makes them structurally identical.
- **Metadata-level (deploy time):** Each Claim instance carries `apiVersion` + `metadata.fqn`. The platform reads these and matches `#claim` requests to `#api` registrations by FQN.

There is no string `type` field. Identity is the CUE definition's metadata FQN.

### Placement rules

| Primitive   | Component-level | Module-level | Rationale |
|-------------|-----------------|--------------|-----------|
| `#Resource` | yes             | no           | Resources are component-internal; shared resources should be a separate component |
| `#Claim`    | yes             | yes          | Component-level for data-plane needs; module-level for platform-relationship |
| `#Api`      | no              | yes          | Capabilities are registered by the module-as-unit |
| `#Trait`    | yes             | no           | Unchanged |

## Before / After

### Before — current `#Module`

```cue
#Module: {
    metadata:    {...}
    #components: {...}
    #policies?:  {...}
    #config:     _
    debugValues: _
}
```

A web app needing Postgres has nowhere to declare that need. The catalog does not ship a `ManagedDatabase` primitive. A Postgres operator Module has nowhere to register that it fulfills `ManagedDatabase`.

### After — flat `#Module` + `#Claim` + `#Api`

A web app:

```cue
#Module & {
    metadata: {modulePath: "example.com/apps", name: "web", version: "0.1.0"}
    #config: { replicas: int | *2 }
    #components: { web: ... }
    #claims: db: data.#ManagedDatabaseClaim & {
        #spec: managedDatabase: { engine: "postgres", version: "16", sizeGB: 50 }
    }
}
```

A Postgres operator:

```cue
#Module & {
    metadata: {modulePath: "vendor.com/operators", name: "pg", version: "0.5.0"}
    #components: {
        controller: ...
        crd:        ...   // #CRDsResource installs Postgres CRD
        rbac:       ...
    }
    #lifecycles: install: ...
    #apis: managed_db: api.#Api & {
        schema: data.#ManagedDatabaseClaim
        metadata: description: "Postgres-backed implementation of ManagedDatabase"
    }
}
```

An API-only Module (declares an API for the platform self-service catalog without deploying components):

```cue
#Module & {
    metadata: {modulePath: "example.com/apis", name: "vector-index", version: "0.1.0"}
    #config: { /* the API parameter schema */ }
    #apis: vec: api.#Api & {
        schema: vectordb.#VectorIndexClaim
        metadata: description: "Self-service VectorIndex contract"
    }
}
```

Same `#Module` type. Three different shapes filled. None of the unfilled slots add cognitive overhead — they are simply absent.

## File Layout

| Path | Status | Purpose |
|------|--------|---------|
| `catalog/core/v1alpha1/module/module.cue` | Modified | Adds `#lifecycles`, `#workflows`, `#claims`, `#apis`; keeps `#policies` |
| `catalog/core/v1alpha1/primitives/claim.cue` | New | `#Claim` primitive |
| `catalog/core/v1alpha1/primitives/api.cue` | New | `#Api` primitive |
| `catalog/opm/v1alpha1/claims/` | New | Well-known commodity Claim definitions |
| `catalog/docs/core/definition-types.md` | Modified | Litmus updates, decision flowchart entries for `#Claim` and `#Api` |
| `catalog/docs/core/primitives.md` | Modified | Reference entries for `#Claim` and `#Api` |
