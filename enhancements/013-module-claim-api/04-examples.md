# Examples — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

Four worked examples illustrate the new shape:

1. **Application Module** — a web app with a component-level claim
2. **Application Module with module-level claim** — a multi-component app with a platform-relationship claim
3. **Operator Module** — a Postgres operator that fulfills the well-known `ManagedDatabase` claim
4. **Specialty vendor + consumer** — a vendor publishes `VectorIndex`; a consumer module uses it
5. **API-only Module** — a self-service catalog entry with no deployable components

## Example 1 — Application Module with component-level claim

A stateless web application that needs a Postgres database. The `#Claim` lives inside the component because the dependency is a per-component data-plane need.

```cue
package web_app

import (
    "opmodel.dev/core/v1alpha1/module@v1"
    container "opmodel.dev/opm/v1alpha1/resources/workload@v1"
    data "opmodel.dev/opm/v1alpha1/claims/data@v1"
)

webApp: module.#Module & {
    metadata: {
        modulePath: "example.com/apps"
        name:       "web-app"
        version:    "0.1.0"
    }

    #config: {
        replicas: int | *2
        image:    string | *"example.com/web:1.0"
    }

    #components: {
        web: {
            #resources: {
                container: container.#ContainerResource & {
                    #spec: container: { image: #config.image }
                }
            }
            #claims: {
                db: data.#ManagedDatabaseClaim & {
                    #spec: managedDatabase: {
                        engine:  "postgres"
                        version: "16"
                        sizeGB:  20
                    }
                }
            }
        }
    }
}
```

## Example 2 — Application Module with module-level claim

A multi-component app that needs a public DNS name and a workload identity shared across components. These are platform-relationship needs, not per-component data-plane needs, so they live at module level.

```cue
package payments_app

import (
    "opmodel.dev/core/v1alpha1/module@v1"
    platform "opmodel.dev/opm/v1alpha1/claims/platform@v1"
)

paymentsApp: module.#Module & {
    metadata: {
        modulePath: "example.com/apps"
        name:       "payments"
        version:    "1.2.0"
    }

    #components: {
        api:    {...}
        worker: {...}
    }

    #claims: {
        // Module-level: DNS hostname for the entire module
        hostname: platform.#HostnameClaim & {
            #spec: hostname: { fqdn: "payments.example.com" }
        }
        // Module-level: shared workload identity for all components
        identity: platform.#WorkloadIdentityClaim & {
            #spec: workloadIdentity: { name: "payments-prod", roles: ["pubsub-publisher"] }
        }
    }
}
```

## Example 3 — Operator Module that fulfills `ManagedDatabase`

A vendor ships a Postgres operator. The Module deploys the controller and CRDs as components, declares an install lifecycle, and registers an `#Api` that fulfills the well-known `ManagedDatabase` commodity contract.

```cue
package postgres_operator

import (
    "opmodel.dev/core/v1alpha1/module@v1"
    "opmodel.dev/core/v1alpha1/primitives@v1"
    container "opmodel.dev/opm/v1alpha1/resources/workload@v1"
    crd "opmodel.dev/opm/v1alpha1/resources/extension@v1"
    rbac "opmodel.dev/opm/v1alpha1/resources/security@v1"
    data "opmodel.dev/opm/v1alpha1/claims/data@v1"
)

postgresOperator: module.#Module & {
    metadata: {
        modulePath: "vendor.com/operators"
        name:       "postgres"
        version:    "0.5.0"
    }

    #config: {
        operatorImage: string | *"vendor.com/pg-operator:0.5.0"
        watchAllNamespaces: bool | *true
    }

    #components: {
        controller: {
            #resources: {
                deployment: container.#ContainerResource & {
                    #spec: container: { image: #config.operatorImage }
                }
                serviceAccount: rbac.#ServiceAccountResource & {...}
                role:           rbac.#RoleResource & {...}
            }
        }
        crds: {
            #resources: {
                postgres: crd.#CRDsResource & {
                    #spec: crds: postgres: {
                        group:    "postgres.vendor.com"
                        kind:     "Postgres"
                        // ... full CRD spec
                    }
                }
            }
        }
    }

    #lifecycles: {
        install: {...}   // controller readiness → CRDs registered → ready
    }

    #apis: {
        managedDb: primitives.#Api & {
            schema: data.#ManagedDatabaseClaim
            metadata: {
                description: "Postgres-backed implementation of ManagedDatabase. Spawns a Postgres CRD instance per claim."
                examples: {
                    small:  { engine: "postgres", version: "16", sizeGB: 10 }
                    medium: { engine: "postgres", version: "16", sizeGB: 50, highAvailability: true }
                }
            }
        }
    }
}
```

## Example 4 — Specialty vendor + consumer

A vendor publishes a specialty `VectorIndex` Claim type in their own CUE package. A consumer Module imports it and claims an instance.

### Vendor publishes (catalog package)

```cue
// vendor.com/vectordb/v1alpha1/claims/vector_index.cue
package vectordb

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#VectorIndex: {
    dimensions!: int & >0
    metric!:     "cosine" | "euclidean" | "dot"
}

#VectorIndexDefaults: {
    metric: "cosine"
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

### Vendor's operator Module fulfills

```cue
// vendor.com/vectordb/v1alpha1/operator/operator.cue
package operator

import (
    "opmodel.dev/core/v1alpha1/module@v1"
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
    vectordb "vendor.com/vectordb/v1alpha1/claims@v1"
)

vectordbOperator: module.#Module & {
    metadata: {
        modulePath: "vendor.com/vectordb/v1alpha1"
        name:       "operator"
        version:    "0.1.0"
    }
    #components: {...}
    #apis: {
        vec: prim.#Api & {
            schema: vectordb.#VectorIndexClaim
            metadata: description: "Vendor implementation of VectorIndex"
        }
    }
}
```

### Consumer claims

```cue
package ml_app

import (
    "opmodel.dev/core/v1alpha1/module@v1"
    vectordb "vendor.com/vectordb/v1alpha1/claims@v1"
)

mlApp: module.#Module & {
    metadata: {modulePath: "example.com/apps", name: "ml-app", version: "0.1.0"}
    #components: {
        inference: {
            #claims: {
                vec: vectordb.#VectorIndexClaim & {
                    #spec: vectorIndex: { dimensions: 1536, metric: "cosine" }
                }
            }
        }
    }
}
```

The consumer imports the vendor's CUE package directly. CUE unification matches the consumer's `#claims.vec` to the vendor operator's `#apis.vec` because both reference the same `#VectorIndexClaim` definition (same `metadata.fqn`).

## Example 5 — API-only Module

A platform team ships a Module that publishes an API surface for the OPM self-service catalog without deploying any runtime components. The Module's `#config` carries the API parameter schema; an `#Api` registers it.

```cue
package image_registry_api

import (
    "opmodel.dev/core/v1alpha1/module@v1"
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
    platform "opmodel.dev/opm/v1alpha1/claims/platform@v1"
)

imageRegistryApi: module.#Module & {
    metadata: {
        modulePath: "example.com/apis"
        name:       "image-registry"
        version:    "0.1.0"
    }

    #config: {
        registry: { url: string, credentials: _ }
    }

    #apis: {
        registry: prim.#Api & {
            schema: platform.#ImageRegistryClaim
            metadata: description: "Self-service image registry contract"
        }
    }

    // No #components — this Module is API-only.
}
```

## Summary

Same `#Module` type covers all five shapes. None of the unfilled slots add cognitive overhead — they are simply absent. Component-level and module-level `#claims` work side-by-side. Operators add `#apis` without changing the shape further. Specialty Claims extend the ecosystem without catalog PRs.
