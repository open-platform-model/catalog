# Design — Requirements Primitive & Backup/Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Design Goals

- Introduce a new primitive type (`#Requirement`) for module-author-declared operational contracts
- Requirements express "what the module needs from the platform" — distinct from Resources (what exists), Traits (how it behaves), and PolicyRules (what rules the platform mandates)
- `#RequirementGroup` groups requirements at the module level and targets them to components via `appliesTo`, mirroring the `#Policy` construct pattern
- Define backup and restore as the first two requirement types using this primitive
- The CLI can execute `opm release restore <release> --snapshot <id>` using only the module's declared restore requirement
- Both **in-place restore** and **disaster recovery** are supported as distinct scenarios
- The design is **provider-agnostic** — K8up is an implementation detail of the Kubernetes provider

---

## Non-Goals (v1)

- Automatic restore without operator confirmation
- Cross-module restore ordering
- Automatic secret backup/recovery
- Database-specific restore logic (module authors encode this in hooks)
- Pod security context configuration for backup/restore pods
- Environment-level backend defaults

---

## The Primitive Taxonomy Gap

The current OPM primitive model answers four questions:

| Primitive | Question | Written by |
|-----------|----------|-----------|
| `#Resource` | "What must exist?" | Module author |
| `#Trait` | "How does it behave?" | Module author |
| `#Blueprint` | "What is the reusable pattern?" | Module author |
| `#PolicyRule` | "What rules must be followed?" | Platform team |

A fifth question is missing:

| Primitive | Question | Written by |
|-----------|----------|-----------|
| **`#Requirement`** | **"What does this module need from the platform?"** | **Module author** |

This gap became visible through backup/restore testing on kind-opm-dev (2026-03-28). The module author knows what data to protect and how to verify restore success, but has no way to declare this as a contract. Three alternative approaches were explored (PolicyRule, Hybrid, pure Trait) and each revealed the same taxonomic mismatch — see the reference appendix in README.md.

### Why Not Traits?

Traits express behavioral preferences — "I want 3 replicas," "I expose port 8096." The platform fulfills them, but they configure the component *itself*. A backup requirement is different: it tells the platform to act *on behalf of* the component. The module doesn't consume backup configuration in its spec the way it consumes scaling or health check configuration.

### Why Not PolicyRules?

PolicyRules flow platform → module. They express governance mandates: "every stateful workload must have resource limits." Backup/restore flows module → platform. The module author declares a need; the platform fulfills it. These are opposite directions.

### Why Not Interfaces?

RFC-0004 Interfaces (`provides`/`requires`) are **data contracts** — the shape flows into the component as typed fields (`requires.db.host`). Requirements are **operational contracts** — the platform acts on the component, it doesn't inject data into it. A requirement has no `#shape` that the module author references.

---

## The `#Requirement` Primitive

```cue
#Requirement: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Requirement"

    metadata: {
        modulePath!: #ModulePathType
        version!:    string
        name!:       #NameType
        fqn:         #FQNType & "\(modulePath)/\(name)@\(version)"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // The requirement contract schema — what the module author declares
    #spec!: (strings.ToCamel(metadata.name)): _

    // Defaults for the spec
    #defaults: #spec
}
```

Key properties:

- **Follows the same metadata pattern** as Resource, Trait, Blueprint, PolicyRule — modulePath, version, name, computed FQN
- **Has a `#spec`** that contributes a uniquely-named field, preventing collisions when multiple requirements compose
- **No `enforcement` field** — a requirement is inherently required. If the platform cannot fulfill it, the runtime (CLI) prints a warning that the requirement is not enabled/provided
- **Provider-agnostic** — the requirement schema declares the contract; the transformer (or CLI) implements fulfillment

---

## The `#RequirementGroup` Construct

Analogous to `#Policy` (which groups `#PolicyRule` instances), `#RequirementGroup` groups requirements and targets them to components:

```cue
#RequirementGroup: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "RequirementGroup"

    metadata: {
        name!: #NameType
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Requirements grouped by this requirement group
    #requirements: [ReqFQN=string]: #Requirement & {
        metadata: name: string | *ReqFQN
    }

    // Which components this requirement group applies to
    appliesTo: {
        matchLabels?: #LabelsAnnotationsType
        components?:  [...]
    }

    _allFields: {
        if #requirements != _|_ {
            for _, req in #requirements {
                if req.#spec != _|_ {
                    for k, v in req.#spec {
                        (k): v
                    }
                }
            }
        }
    }

    spec: close(_allFields)
}
```

### Where it lives in `#Module`

```cue
#Module: {
    #components: [Id=string]: component.#Component & { ... }

    // Module-level requirements (module-author-defined)
    #requirements?: [Id=string]: #RequirementGroup

    // Policies move to #PlatformModule in a future enhancement
    #policies?: [Id=string]: policy.#Policy

    #config: _
    debugValues: _
}
```

The `#requirements` field is a **map** keyed by a user-chosen name. Each entry is a `#RequirementGroup` that:
1. Contains one or more `#Requirement` instances
2. Targets specific components via `appliesTo`

This enables per-component variation within a single module:

```cue
#requirements: {
    "app-data-protection": {
        appliesTo: components: ["jellyfin"]
        // backup + restore for the main app
    }
    "db-data-protection": {
        appliesTo: components: ["postgres"]
        // different backup strategy for the database
    }
}
```

---

## Motivating Use Case 1: Backup & Restore

### `#BackupRequirement`

```cue
#BackupRequirement: prim.#Requirement & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/requirements/data"
        version:    "v1"
        name:       "backup"
        description: "Declares periodic backup for a component's persistent data"
    }
    #spec: close({backup: #BackupSchema})
}

#BackupSchema: {
    // What to protect
    targets: [...{
        volume!:   string
        mountPath: string
    }]

    // How to prepare for a consistent snapshot
    preBackupHook?: {
        image!:   string
        command!: [...string]
        volumeMount?: {
            volume!:   string
            mountPath: *"/data" | string
        }
    }

    // Scheduling and retention
    schedule:      *"0 2 * * *" | string
    checkSchedule: *"0 4 * * 0" | string
    pruneSchedule: *"0 5 * * 0" | string
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // Backend (provided by the release, not the module)
    backend: {
        s3: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }
        repoPassword!: schemas.#Secret
    }
}
```

### `#RestoreRequirement`

```cue
#RestoreRequirement: prim.#Requirement & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/requirements/data"
        version:    "v1"
        name:       "restore"
        description: "Declares how the platform should restore this component from backup"
    }
    #spec: close({restore: #RestoreSchema})
}

#RestoreSchema: {
    // What to restore — references volumes declared in the component
    targets: [...{
        volume!:   string
        mountPath: string
    }]

    // Health verification after restore
    healthCheck: {
        path!: string
        port!: int
    }

    // Scenario: in-place restore
    inPlace: {
        requiresScaleDown: *true | bool
    }

    // Scenario: full disaster recovery
    disasterRecovery: {
        managedByOPM: *true | bool
    }
}
```

### Module-level composition

```cue
#Module & {
    #components: {
        jellyfin: component.#Component & workload.#Container & workload.#Scaling & {
            spec: {
                container: image: repository: "linuxserver/jellyfin"
                scaling: count: 1
            }
        }
    }

    #requirements: {
        "jellyfin-data-protection": #RequirementGroup & {
            appliesTo: components: ["jellyfin"]

            #requirements: {
                (data.#BackupRequirement.metadata.fqn): data.#BackupRequirement & {
                    #spec: backup: {
                        targets: [{volume: "config", mountPath: "/config"}]
                        preBackupHook: {
                            image: "alpine:3.19"
                            command: ["sh", "-c", "apk add --no-cache sqlite && sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE);' && sqlite3 /config/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE);'"]
                            volumeMount: {volume: "config", mountPath: "/config"}
                        }
                        backend: #config.backup.backend
                    }
                }
                (data.#RestoreRequirement.metadata.fqn): data.#RestoreRequirement & {
                    #spec: restore: {
                        targets: [{volume: "config", mountPath: "/config"}]
                        healthCheck: {path: "/health", port: 8096}
                    }
                }
            }

            spec: {
                backup: {
                    targets: [{volume: "config", mountPath: "/config"}]
                    // ... values from release
                }
                restore: {
                    targets: [{volume: "config", mountPath: "/config"}]
                    healthCheck: {path: "/health", port: 8096}
                }
            }
        }
    }
}
```

---

## Motivating Use Case 2: Shared Network

Today, `#SharedNetwork` is modeled as a `#PolicyRule` composed into a `#Policy`. But it is conceptually a module-author declaration ("my components need to communicate"), not a platform governance rule. It fits naturally as a requirement:

```cue
#SharedNetworkRequirement: prim.#Requirement & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/requirements/network"
        version:    "v1"
        name:       "shared-network"
        description: "Declares that targeted components share a network namespace"
    }
    #spec: close({sharedNetwork: #SharedNetworkSchema})
}
```

Module-level usage:

```cue
#requirements: {
    "internal-comms": #RequirementGroup & {
        appliesTo: matchLabels: {
            "core.opmodel.dev/workload-type": "stateless"
        }
        #requirements: {
            (network.#SharedNetworkRequirement.metadata.fqn): network.#SharedNetworkRequirement
        }
        spec: sharedNetwork: {
            networkConfig: dnsPolicy: "ClusterFirst"
        }
    }
}
```

This is a better fit than PolicyRule because:
- The module author writes it (not the platform team)
- It expresses a need ("these components need to communicate"), not a mandate ("you must follow this rule")
- The platform fulfills it (configures networking), the module declares intent

---

## Future Requirements (Not in Scope)

The `#Requirement` primitive is designed to grow. Anticipated future requirements include:

| Requirement | Module declares | Platform fulfills |
|-------------|----------------|-------------------|
| `#DnsRequirement` | "I need a DNS record for this hostname" | Creates DNS record via external-dns, Route53, etc. |
| `#CertificateRequirement` | "I need a TLS certificate for these domains" | Provisions via cert-manager, ACME, etc. |
| `#DatabaseRequirement` | "I need a PostgreSQL database" | Provisions managed DB or deploys in-cluster |
| `#StorageRequirement` | "I need persistent storage with these characteristics" | Provisions PV/PVC with appropriate storage class |

These are not designed in this enhancement but validate that `#Requirement` is a general-purpose primitive, not a one-off for backup/restore.

---

## How Transformers Discover Requirements

Requirements use the same FQN-based matching as traits. A transformer declares `requiredRequirements` (and optionally `optionalRequirements`) to match against components that have requirements applied via `appliesTo`:

```cue
#BackupTransformer: transformer.#Transformer & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
        name:       "backup-transformer"
    }

    // The transformer matches components that have the backup requirement applied
    requiredRequirements: {
        (data.#BackupRequirement.metadata.fqn): data.#BackupRequirement
    }

    optionalRequirements: {
        (data.#RestoreRequirement.metadata.fqn): data.#RestoreRequirement
    }

    #transform: {
        #component: _
        #context: transformer.#TransformerContext
        output: { /* K8up Schedule CR */ }
    }
}
```

The render pipeline resolves `appliesTo` at evaluation time, attaching requirements to matched components before transformer dispatch.

---

## CLI Integration

The CLI reads restore requirements from rendered releases to orchestrate recovery. See [10-cli-integration.md](10-cli-integration.md) for full command surface.

```bash
# In-place restore
opm release restore releases/kind_opm_dev/jellyfin/release.cue \
  --snapshot 574dc25a

# Full disaster recovery
opm release restore releases/kind_opm_dev/jellyfin/release.cue \
  --snapshot 574dc25a \
  --scenario disasterRecovery
```

If a release does not declare a restore requirement, the CLI prints a warning:
```
warning: release "jellyfin" does not declare a restore requirement — manual restore required
```

---

## Relationship to Other OPM Concepts

| Concept | Direction | Scope | `#Requirement` relationship |
|---------|-----------|-------|----------------------------|
| `#PolicyRule` / `#Policy` | Platform → Module | Governance mandates | **Distinct.** Policies enforce rules. Requirements declare needs. |
| `#Interface` (RFC-0004) | Bidirectional | Communication contracts | **Complementary.** Interfaces describe data flow between components. Requirements describe operational needs from the platform. Both move to module level. |
| `#Trait` | Module → Component | Behavioral preferences | **Distinct.** Traits configure the component itself. Requirements ask the platform to act on behalf of the component. |
| `#Resource` | Module → Component | Deployable entities | **Distinct.** Resources define what exists. Requirements define what is needed. |
