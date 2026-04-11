# Design — `#Claim` Primitive & Policy Broadening

## Design Goals

- Introduce `#Claim` as a component-level primitive that composes into Blueprints alongside Resources and Traits
- Claims declare what a component needs from the platform — the platform fulfills
- Claims contribute a named field to the component `spec`, like Traits
- Broaden `#Policy` to contain two primitive types: `#Rule` (platform -> module) and `#Orchestration` (module -> platform, cross-component)
- The design is provider-agnostic — K8up, Velero, RDS, Cloud SQL are implementation details
- The CLI reads Policy orchestrations to execute operations (e.g., `opm release restore`)

## Non-Goals (v1)

- `#Offer` primitive (what a component provides) — deferred to enhancement 007
- Cross-module auto-wiring (requires both `#Claim` and `#Offer`)
- Full CUE late-binding implementation (needs spike; design intent documented here)
- Interface versioning strategy (additive-only for v1)

---

## The Updated Taxonomy

### Primitives (component-level, Blueprint-composable)

| Primitive | Question | Who controls |
|-----------|----------|-------------|
| `#Resource` | "What must exist?" | Module author |
| `#Trait` | "How does it behave?" | Module author |
| `#Claim` | "What does it need from the platform?" | Platform fulfills |
| `#Offer` | "What does it provide?" | Module author (deferred to 007) |
| `#Blueprint` | "What is the reusable pattern?" | Composes Resource + Trait + Claim + Offer |

### Policy primitives (module-level, in `#Policy` construct)

| Primitive | Direction | Who writes it |
|-----------|-----------|--------------|
| `#Rule` | Platform -> Module | Platform team |
| `#Orchestration` | Module -> Platform (cross-component) | Module author |

---

## The `#Claim` Primitive

A Claim is a component-level primitive that declares what the component needs from the platform. It contributes a named field to the component `spec`, exactly like a Trait.

```cue
#Claim: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Claim"

    metadata: {
        modulePath!: #ModulePathType
        version!:    string
        name!:       #NameType
        fqn:         #FQNType & "\(modulePath)/\(name)@\(version)"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Optional: typed fields the module author can wire into component specs.
    // When present, the platform fills these with concrete values at deploy time.
    // When absent, the claim is purely operational (backup scheduling, etc.)
    #shape?: {...}

    // The claim contract schema
    #spec!: (strings.ToCamel(metadata.name)): _

    // Defaults
    #defaults: #spec
}
```

### Two flavors of Claim

**Data claims** (have `#shape`): The module author wires typed fields into component specs. The platform injects concrete values at deploy time.

```cue
#PostgresClaim: #Claim & {
    metadata: { name: "postgres" }
    #shape: {
        host!: string, port: uint | *5432, dbName!: string,
        username!: string, password!: string
    }
    #spec: close({postgres: #shape})
}
```

**Operational claims** (no `#shape`): The platform acts on the component. No fields to wire.

```cue
#BackupClaim: #Claim & {
    metadata: { name: "backup" }
    #spec: close({backup: #BackupSchema})
}
```

Both compose into Blueprints identically.

### How Claims compose into Components

```cue
#Component: {
    metadata: { ... }
    #resources:  [FQN=string]: #Resource
    #traits?:    [FQN=string]: #Trait
    #claims?:    [FQN=string]: #Claim      // NEW
    #blueprints?: [FQN=string]: #Blueprint

    _allFields: {
        // Merge specs from resources, traits, AND claims
        for _, res in #resources { if res.spec != _|_ { res.spec } }
        if #traits != _|_ {
            for _, trait in #traits { if trait.spec != _|_ { trait.spec } }
        }
        if #claims != _|_ {
            for _, claim in #claims { if claim.spec != _|_ { claim.spec } }
        }
        // ... blueprints
    }

    spec: close({_allFields})
}
```

### How Claims compose into Blueprints

```cue
#Blueprint: {
    metadata: { ... }
    composedResources: [FQN=string]: #Resource
    composedTraits:    [FQN=string]: #Trait
    composedClaims:    [FQN=string]: #Claim    // NEW
}

// Example: a reusable pattern for stateful workloads with backup
#BackedUpStatefulWorkload: #Blueprint & {
    composedResources: {
        (workload.#ContainerResource.metadata.fqn): workload.#ContainerResource
        (storage.#VolumesResource.metadata.fqn):    storage.#VolumesResource
    }
    composedTraits: {
        (workload.#ScalingTrait.metadata.fqn):     workload.#ScalingTrait
        (workload.#HealthCheckTrait.metadata.fqn): workload.#HealthCheckTrait
    }
    composedClaims: {
        (data.#BackupClaim.metadata.fqn): data.#BackupClaim
    }
}
```

### Data claim wiring

When a claim has `#shape`, the module author wires its fields into the component spec:

```cue
userApi: #StatelessWorkload & data.#PostgresClaim & {
    spec: {
        container: {
            image: repository: "myapp"
            env: {
                DB_HOST: spec.postgres.host     // wired from claim shape
                DB_PORT: "\(spec.postgres.port)" // CUE validates at definition time
            }
        }
        postgres: {
            // Platform fills these at deploy time
        }
    }
}
```

CUE guarantees:
- `spec.postgres.host` exists because `#PostgresClaim.#shape` defines `host!: string`
- A typo like `spec.postgres.hostname` fails at definition time
- The platform must provide concrete values before deployment

---

## Broadened `#Policy`

`#Policy` gains a second primitive type alongside `#Rule`:

```cue
#Policy: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Policy"

    metadata: { name!, labels?, annotations? }

    // Governance rules (platform -> module)
    #rules?: [RuleFQN=string]: #Rule

    // Cross-component orchestrations (module -> platform)
    #orchestrations?: [OrchFQN=string]: #Orchestration

    // Which components this policy applies to
    appliesTo: {
        matchLabels?: #LabelsAnnotationsType
        components?:  [...]
    }

    spec: close(_allFields)
}
```

### `#Rule` (replaces `#PolicyRule`)

Platform-team-defined governance mandates. Unchanged from existing `#PolicyRule` semantics.

```cue
#Rule: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Rule"
    metadata:   { modulePath, version, name, fqn }
    enforcement!: {
        mode!:        "deployment" | "runtime" | "both"
        onViolation!: "block" | "warn" | "audit"
    }
    #spec!: (strings.ToCamel(metadata.name)): _
}
```

### `#Orchestration`

Module-author-defined cross-component coordination. No enforcement — this is a declaration, not a mandate.

```cue
#Orchestration: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Orchestration"
    metadata:   { modulePath, version, name, fqn }
    #spec!: (strings.ToCamel(metadata.name)): _
}
```

### Orchestration types

```cue
#RestoreOrchestration: #Orchestration & {
    metadata: { name: "restore" }
    #spec: close({restore: #RestoreSchema})
}

#SharedNetworkOrchestration: #Orchestration & {
    metadata: { name: "shared-network" }
    #spec: close({sharedNetwork: #SharedNetworkSchema})
}
```

### Module-level usage

```cue
#Module & {
    #components: {
        "jellyfin": #BackedUpStatefulWorkload & data.#PostgresClaim & { ... }
    }

    #policies: {
        "restore-plan": #Policy & {
            appliesTo: components: ["jellyfin"]
            #orchestrations: {
                (ops.#RestoreOrchestration.metadata.fqn): ops.#RestoreOrchestration & {
                    #spec: restore: {
                        healthCheck: { path: "/health", port: 8096 }
                        inPlace: { requiresScaleDown: true }
                        disasterRecovery: { managedByOPM: true }
                    }
                }
            }
        }
        "internal-comms": #Policy & {
            appliesTo: matchLabels: { "core.opmodel.dev/workload-type": "stateless" }
            #orchestrations: {
                (network.#SharedNetworkOrchestration.metadata.fqn): network.#SharedNetworkOrchestration & {
                    #spec: sharedNetwork: { networkConfig: dnsPolicy: "ClusterFirst" }
                }
            }
        }
    }
}
```

---

## How It All Fits Together

```text
COMPONENT LEVEL (Blueprint-composable):

  jellyfin: #BackedUpStatefulWorkload & #PostgresClaim & {
      spec: {
          container: { ... }           <- #Resource
          scaling: { count: 1 }        <- #Trait
          healthCheck: { ... }         <- #Trait
          backup: {                    <- #Claim (operational, no shape)
              targets: [{volume: "config"}]
              backend: #config.backup.backend
          }
          postgres: {                  <- #Claim (data, has shape)
              /* platform fills */
          }
          container: env: {
              DB_HOST: spec.postgres.host  <- wired from claim shape
          }
      }
  }

MODULE LEVEL (Policy):

  #policies: {
      "restore-plan": {
          appliesTo: components: ["jellyfin"]
          #orchestrations: {
              restore: {               <- #Orchestration
                  healthCheck: { path: "/health", port: 8096 }
                  disasterRecovery: { managedByOPM: true }
              }
          }
      }
  }

CLI reads the RestoreOrchestration to execute:
  opm release restore release.cue --snapshot 574dc25a
```

---

## Counterpart: `#Offer` (Enhancement 007)

The companion to `#Claim`. While `#Claim` declares what a component *needs* (component-level), `#Offer` declares what a module *provides* (module-level). Offers are the supply side of the Claim/Offer contract.

Key design properties (see [007-offer-primitive](../007-offer-primitive/) for full design):

- **Module-level**: Offers are declared on `#Module`, not on components. A capability is provided by the whole module (e.g., the K8up operator), not by a single component within it.
- **Paired**: Every well-known Claim has a corresponding well-known Offer definition.
- **Linked to Transformers**: Capability offers carry their Transformers. This allows providers (K8up, Velero, cert-manager) to package controller + Offer + Transformer as a unit.

```cue
// Enhancement 007: Module-level Offer with linked Transformers
k8upModule: #Module & {
    #components: {
        "operator": #StatelessWorkload & { ... }
    }
    #offers: {
        (#BackupOffer.metadata.fqn): #BackupOffer & {
            #transformers: {
                (schedule_t.metadata.fqn):    schedule_t
                (prebackup_t.metadata.fqn):   prebackup_t
            }
        }
    }
}
```

The Platform aggregates Offers from all composed Providers, enabling pre-render validation: "Is this claim satisfied by an installed Offer?"

---

## Open: CUE Late-Binding

Data claims rely on `spec.postgres.host` being a type (`string`) at author time and a concrete value (`"pg.svc.cluster.local"`) at deploy time. The mechanism for this injection needs a spike/PoC. See [05-fulfillment.md](05-fulfillment.md).
