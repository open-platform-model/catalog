# Schema — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

## Summary

Three CUE definitions land in `core/v1alpha1`:

- `#Claim` — primitive in `core/v1alpha1/primitives/claim.cue`
- `#Api` — primitive in `core/v1alpha1/primitives/api.cue`
- Updated `#Module` — modified `core/v1alpha1/module/module.cue`

A worked commodity definition triplet illustrates the catalog pattern:

- `#ManagedDatabase` (schema)
- `#ManagedDatabaseDefaults` (defaults)
- `#ManagedDatabaseClaim` (Claim wrapper)

## `#Claim` (primitive)

```cue
package primitives

import (
    t "opmodel.dev/core/v1alpha1/types@v1"
)

// #Claim: Defines the shape of an ecosystem-supplied need.
// The same primitive serves as both the type definition (when authored in
// a catalog or vendor package) and the request (when used in a Module's
// #claims). Identity is the metadata FQN — there is no string type field.
//
// apiVersion is left open so concrete Claim definitions (e.g.
// #ManagedDatabaseClaim) set their own apiVersion. The base #Claim does
// not pin one.
#Claim: {
    apiVersion!: string                            // open — set by concrete claim
    kind:        "Claim"

    metadata: {
        modulePath!: t.#ModulePathType              // "opmodel.dev/opm/v1alpha1/claims/data"
        version!:    t.#MajorVersionType            // "v1"
        name!:       t.#NameType                    // "managed-database"
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // MUST be an OpenAPIv3 compatible schema.
    // The field name is the camelCase of metadata.name (kebab-case names
    // are converted: "managed-database" => "managedDatabase").
    #spec!: ((t.#KebabToCamel & {"in": metadata.name}).out): _
}

#ClaimMap: [string]: _
```

## `#Api` (primitive)

```cue
package primitives

import (
    t "opmodel.dev/core/v1alpha1/types@v1"
)

// #Api: Registers a capability that this Module supplies to the platform.
// One #Api embeds exactly one #Claim as its schema field (1:1).
// #Api is purely declarative — the platform may use it to populate a
// self-service catalog, a deploy-time match cache, or both.
//
// CRD installation is NOT part of #Api. Operators continue to ship CRDs
// via #CRDsResource inside #components.
#Api: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Api"

    // Embedded #Claim definition — commodity import or specialty.
    // The embedded Claim's metadata FQN is what the platform matches against.
    schema!: #Claim

    metadata?: {
        description?: string
        examples?:    _
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }
}

#ApiMap: [string]: _
```

## Updated `#Module`

```cue
package module

import (
    cue_uuid "uuid"
    t "opmodel.dev/core/v1alpha1/types@v1"
    component "opmodel.dev/core/v1alpha1/component@v1"
    policy "opmodel.dev/core/v1alpha1/policy@v1"
    lifecycle "opmodel.dev/core/v1alpha1/lifecycle@v1"
    workflow "opmodel.dev/core/v1alpha1/workflow@v1"
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

// #Module: The portable application/API/operator blueprint created by
// developers, vendors, or platform teams.
#Module: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Module"

    metadata: {
        modulePath!: t.#ModulePathType
        name!:       t.#NameType
        version!:    t.#VersionType
        fqn:         t.#ModuleFQNType & "\(modulePath)/\(name):\(version)"
        uuid:        t.#UUIDType & cue_uuid.SHA1(t.OPMNamespace, fqn)
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        defaultNamespace?: string
        description?:      string
        labels?:           t.#LabelsAnnotationsType
        annotations?:      t.#LabelsAnnotationsType

        labels: {
            "module.opmodel.dev/name":    "\(name)"
            "module.opmodel.dev/version": "\(version)"
            "module.opmodel.dev/uuid":    "\(uuid)"
        }
    }

    // Nucleus
    #config:     _
    debugValues: _

    #components: [Id=string]: component.#Component & {
        metadata: {
            name: string | *Id
            labels: "component.opmodel.dev/name": name
        }
    }

    // Inward — operate on the module itself
    #policies?:   [Id=string]: policy.#Policy
    #lifecycles?: [Id=string]: lifecycle.#Lifecycle
    #workflows?:  [Id=string]: workflow.#Workflow

    // Outward — visible to the platform and other modules
    #claims?:     [Id=string]: prim.#Claim
    #apis?:       [Id=string]: prim.#Api
}

#ModuleMap: [string]: #Module
```

## Worked Commodity Definition Triplet

Lives in `catalog/opm/v1alpha1/claims/data/managed_database.cue`. Mirrors the existing `#Container` / `#ContainerDefaults` / `#ContainerResource` pattern.

```cue
package data

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

// #ManagedDatabase: schema for the ManagedDatabase commodity contract.
#ManagedDatabase: {
    engine!:  "postgres" | "mysql" | "mongodb"
    version!: string
    sizeGB!:  int & >0
    highAvailability?: bool | *false
}

// #ManagedDatabaseDefaults: opinionated defaults for ManagedDatabase.
#ManagedDatabaseDefaults: {
    engine: "postgres"
    sizeGB: 10
    highAvailability: false
}

// #ManagedDatabaseClaim: Claim wrapper that ties the schema to the
// #Claim primitive and pins identity metadata.
#ManagedDatabaseClaim: prim.#Claim & {
    apiVersion: "opmodel.dev/opm/v1alpha1"
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/claims/data"
        version:     "v1"
        name:        "managed-database"
        description: "Well-known commodity contract for a managed relational database."
    }
    #spec: managedDatabase: #ManagedDatabase
}
```

## Specialty Vendor Definition Triplet

Same shape, different package. Lives in the vendor's own CUE module (e.g. `vendor.com/vectordb/v1alpha1/claims/`).

```cue
package vectordb

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#VectorIndex: {
    dimensions!: int & >0
    metric!:     "cosine" | "euclidean" | "dot"
    replicas?:   int | *1
}

#VectorIndexDefaults: {
    metric:   "cosine"
    replicas: 1
}

#VectorIndexClaim: prim.#Claim & {
    apiVersion: "vendor.com/vectordb/v1alpha1"
    metadata: {
        modulePath:  "vendor.com/vectordb/v1alpha1/claims"
        version:     "v1"
        name:        "vector-index"
        description: "Vendor-specialty contract for a vector index service."
    }
    #spec: vectorIndex: #VectorIndex
}
```

## Field Documentation

### `#Claim`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `apiVersion` | `string` | yes | Open string set by concrete Claim definitions (e.g. `opmodel.dev/opm/v1alpha1`, `vendor.com/x/v1alpha1`) |
| `kind` | `"Claim"` | fixed | Always `"Claim"` |
| `metadata.modulePath` | `t.#ModulePathType` | yes | CUE module path the Claim definition lives in |
| `metadata.version` | `t.#MajorVersionType` | yes | Major version of the Claim definition |
| `metadata.name` | `t.#NameType` | yes | Kebab-case name of the Claim |
| `metadata.fqn` | `t.#FQNType` | computed | `\(modulePath)/\(name)@\(version)` — the deploy-time identity |
| `metadata.description` | `string` | no | Human-readable summary |
| `#spec` | `_` (camelCase field name from `metadata.name`) | yes | OpenAPIv3 schema for the request |

### `#Api`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `apiVersion` | `"opmodel.dev/core/v1alpha1"` | fixed | OPM core |
| `kind` | `"Api"` | fixed | Always `"Api"` |
| `schema` | `#Claim` | yes | Embedded `#Claim` definition — the capability contract |
| `metadata.description` | `string` | no | Self-service catalog description |
| `metadata.examples` | `_` | no | Example values for the self-service catalog |
| `metadata.labels` | `t.#LabelsAnnotationsType` | no | Catalog labels |
| `metadata.annotations` | `t.#LabelsAnnotationsType` | no | Catalog annotations |

### `#Module` — added/changed slots

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `#lifecycles` | `[Id=string]: lifecycle.#Lifecycle` | no | Inward — state transitions |
| `#workflows` | `[Id=string]: workflow.#Workflow` | no | Inward — on-demand operations |
| `#claims` | `[Id=string]: prim.#Claim` | no | Outward — module-level needs |
| `#apis` | `[Id=string]: prim.#Api` | no | Outward — capabilities registered |
