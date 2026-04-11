# Design — `#Directive` Primitive: Backup & Restore

## Design Goals

- Introduce `#Directive` as a primitive type within `#Policy`, alongside `#PolicyRule`
- Directives describe operational behavior the platform executes — no enforcement semantics
- Provider-specific backup directives (K8up first, Velero later)
- Provider-agnostic restore directive consumed by the CLI
- Two self-contained directives: backup generates CRs, restore drives CLI operations

## Non-Goals (v1)

- Component-level placement or Blueprint composition (that's enhancement 006's `#Claim`)
- Data dependency claims (Postgres, Redis connections)
- Cross-module backup coordination
- Environment-level S3 backend defaults
- Generic/universal backup abstraction across providers

---

## The `#Directive` Primitive

`#Directive` follows the same metadata pattern as `#PolicyRule` but omits the `enforcement` block. It lives inside `#Policy` via a new `#directives` map.

```cue
#Directive: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Directive"

    metadata: {
        modulePath!:  t.#ModulePathType   // Example: "opmodel.dev/opm/v1alpha1/directives/data"
        version!:     t.#MajorVersionType // Example: "v1"
        name!:        t.#NameType         // Example: "k8up-backup"
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // MUST be an OpenAPIv3 compatible schema
    // The field and schema exposed by this definition
    #spec!: (strings.ToCamel(metadata.name)): _
}

#DirectiveMap: [string]: #Directive
```

### Comparison with `#PolicyRule`

| Aspect | `#PolicyRule` | `#Directive` |
|--------|--------------|-------------|
| Purpose | Governance rules, security, compliance | Operational behavior the platform executes |
| Enforcement | Required (`mode`, `onViolation`) | None |
| Who writes it | Platform team | Module author |
| Examples | Encryption policy, resource limits | K8up backup, restore procedures |
| Metadata | Same pattern | Same pattern |
| Spec | Same pattern (`#spec!: camelName: _`) | Same pattern |

---

## `#Policy` Changes

`#Policy` gains a `#directives` field alongside `#rules`. The `_allFields` comprehension extends to merge spec fields from both rules and directives into the policy's `spec`.

```cue
#Policy: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Policy"

    metadata: {
        name!: t.#NameType
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // PolicyRules grouped by this policy (governance)
    #rules: [RuleFQN=string]: prim.#PolicyRule & {
        metadata: {
            name: string | *RuleFQN
        }
    }

    // Directives grouped by this policy (operational behavior)
    #directives?: [DirectiveFQN=string]: prim.#Directive & {
        metadata: {
            name: string | *DirectiveFQN
        }
    }

    // Which components this policy applies to
    appliesTo: {
        matchLabels?: t.#LabelsAnnotationsType
        components?: [...component.#Component]
    }

    _allFields: {
        if #rules != _|_ {
            for _, rule in #rules {
                if rule.#spec != _|_ {
                    for k, v in rule.#spec {
                        (k): v
                    }
                }
            }
        }
        if #directives != _|_ {
            for _, directive in #directives {
                if directive.#spec != _|_ {
                    for k, v in directive.#spec {
                        (k): v
                    }
                }
            }
        }
    }

    spec: close(_allFields)
}
```

A `#Policy` may contain only `#rules`, only `#directives`, or both.

---

## Two Directives, Two Consumers

| Directive | Consumer | Provider-specific? | Purpose |
|-----------|----------|-------------------|---------|
| `#K8upBackupDirective` | Transformer | Yes (K8up) | Generate K8up Schedule + PreBackupPod CRs |
| `#RestoreDirective` | CLI | No (repo-format aware) | Browse snapshots, execute restores |

Both are self-contained. Both carry their own backend/repository credentials. Duplication is handled at the module level via `#config` references.

### Why Two Directives Instead of One

Backup is provider-specific — K8up has `checkSchedule`, `pruneSchedule`, Restic retention semantics. Velero has TTL, CSI snapshots, exec-in-container hooks. Abstracting over them wastes effort and leaks provider details into the contract.

Restore is provider-agnostic — the CLI needs repository connection info, what was backed up, and how to restore. It doesn't care whether K8up or Velero created the backups. Restic repos are Restic repos.

Separating them means:
- Adding Velero support = new `#VeleroBackupDirective`, same `#RestoreDirective`
- CLI works unchanged regardless of which backup provider wrote the data

---

## `#K8upBackupDirective`

Unapologetically K8up-specific. Maps closely to K8up's Schedule CR.

```cue
#K8upBackupDirective: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/directives/data"
        version:     "v1"
        name:        "k8up-backup"
        description: "K8up backup scheduling and pre-backup hooks"
    }
    #spec: close({k8upBackup: #K8upBackupDirectiveSchema})
}
```

### `#K8upBackupDirectiveSchema`

```cue
#K8upBackupDirectiveSchema: {
    // K8up scheduling
    schedule!:     string                   // Backup cron schedule (required, no default)
    checkSchedule: *"0 4 * * 0" | string   // Restic repo integrity check
    pruneSchedule: *"0 5 * * 0" | string   // Restic snapshot pruning

    // Restic retention policy
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // K8up backend — S3 + Restic repo password
    backend!: {
        s3: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }
        repoPassword!: schemas.#Secret
    }

    // Per-component backup targets
    // Keys are component names matching Policy.appliesTo
    targets!: [componentName=string]: {
        // Volume targets — file-level backup via Restic
        // Keys reference volume names from the component's spec.volumes
        volumes?: [volumeName=string]: {
            backupPath: *"/" | string  // subtree within the PVC to back up
        }

        // ConfigMap targets — API object export
        configMaps?: [configMapName=string]: {}

        // Secret targets — API object export
        secrets?: [secretName=string]: {}

        // K8up PreBackupPod — runs before this component's backup
        preBackupHook?: {
            image!:   string
            command!: [...string]
            volumeMount?: {
                volume!:   string            // references a volume name from this component
                mountPath: *"/data" | string
            }
        }
    }
}
```

### Design Notes

**No default schedule**: Module author must choose. Backup frequency is a conscious decision, not something that should silently default.

**`checkSchedule` and `pruneSchedule`**: K8up/Restic-specific. These map directly to `restic check` and `restic forget --prune`. Defaults are sensible for most deployments (weekly check, weekly prune).

**`retention` is Restic-native**: `keepDaily`, `keepWeekly`, `keepMonthly` map directly to Restic prune flags. No abstraction layer.

**`backend.s3` only for v1**: K8up supports S3, GCS, Azure, B2, Swift, local, REST. S3 covers MinIO, Garage, AWS S3, and most S3-compatible stores. Additional backends can be added without breaking the schema.

**`preBackupHook` generates K8up PreBackupPod**: The transformer creates a separate K8up PreBackupPod CR from this definition. The hook runs as a temporary pod before each backup.

---

## `#RestoreDirective`

Provider-agnostic. Consumed by the OPM CLI, not by transformers. Describes how to connect to the backup repository, what can be restored, and the restore procedure per component.

```cue
#RestoreDirective: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/directives/data"
        version:     "v1"
        name:        "restore"
        description: "Restore procedures and repository connection for CLI operations"
    }
    #spec: close({restore: #RestoreDirectiveSchema})
}
```

### `#RestoreDirectiveSchema`

```cue
#RestoreDirectiveSchema: {
    // Repository connection — CLI uses to browse and restore snapshots
    repository!: {
        // Backup tool format — determines which CLI tool to use
        format: *"restic" | "kopia"

        // Storage backend
        s3?: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }

        // Repository encryption key
        repoPassword!: schemas.#Secret
    }

    // Per-component restore procedures
    // Definition order = restore order (database before app)
    components!: [componentName=string]: {
        // What was backed up on this component (CLI uses for listing/browsing)
        volumes?: [volumeName=string]: {}
        configMaps?: [configMapName=string]: {}
        secrets?: [secretName=string]: {}

        // Restore procedure
        requiresScaleDown: *true | bool

        healthCheck?: {
            path!: string   // HTTP path to check after restore
            port!: int      // Port to check
        }
    }
}
```

### Design Notes

**Self-contained**: The restore directive carries its own repository connection info. It does not reference the backup directive. Both directives read from the same `#config.backup` values, but structurally they are independent.

**`repository.format`**: The CLI needs to know whether to use `restic` or `kopia` to interact with the repository. K8up uses Restic. Velero defaults to Kopia (Restic deprecated in Velero 1.15+). Default is `"restic"`.

**Definition order is restore order**: CUE preserves struct field order. If the module author writes `database` before `app` in `components`, the CLI restores in that order. No explicit ordering field needed.

**`requiresScaleDown`**: Most stateful workloads need to be scaled to 0 during restore to avoid data corruption. Default is `true`.

**`healthCheck`**: After restore and scale-up, the CLI polls this endpoint to verify the component is healthy. Optional — when absent, the CLI skips health verification.

**No restore implementation details**: The directive describes *what* the CLI should do (scale down, restore volumes, verify health), not *how* (K8up Restore CR vs Velero Restore CR). The CLI chooses the mechanism based on what's available in the cluster.

---

## Module Integration Overview

Module authors add both directives to the same `#policies` entry. Release authors provide environment-specific values via `#config`.

```cue
#Module & {
    #components: {
        jellyfin: workload_blueprints.#StatefulWorkload & {
            spec: statefulWorkload: { /* ... */ }
        }
    }

    #policies: {
        "backup": policy.#Policy & {
            appliesTo: components: [#components.jellyfin]

            #directives: {
                // K8up transformer generates Schedule + PreBackupPod
                (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective & {
                    #spec: k8upBackup: {
                        schedule: #config.backup.schedule
                        backend:  #config.backup.backend

                        targets: {
                            jellyfin: {
                                volumes: {
                                    config: { backupPath: "/data" }
                                }
                                preBackupHook: {
                                    image: "alpine:3.21"
                                    command: ["sh", "-c", "sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)'"]
                                    volumeMount: {
                                        volume:    "config"
                                        mountPath: "/config"
                                    }
                                }
                            }
                        }
                    }
                }

                // CLI reads this for browse/restore
                (data_directives.#RestoreDirective.metadata.fqn): data_directives.#RestoreDirective & {
                    #spec: restore: {
                        repository: {
                            format:       "restic"
                            s3:           #config.backup.backend.s3
                            repoPassword: #config.backup.backend.repoPassword
                        }
                        components: {
                            jellyfin: {
                                volumes: { config: {} }
                                requiresScaleDown: true
                                healthCheck: {
                                    path: "/health"
                                    port: 8096
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

Detailed module and release integration patterns are covered in [04-module-integration.md](04-module-integration.md).

---

## Relationship to Other Enhancements

### Enhancement 004 (archived)

Enhancement 004's component-level `#BackupTrait` + `#PreBackupHookTrait` design is correct mechanically but at the wrong scope. This enhancement moves backup to module-level `#Policy` where it belongs.

### Enhancement 006 (Draft, not superseded)

Enhancement 006's `#Claim` + `#Orchestration` design is broader — it handles data dependencies (Postgres, Redis), Blueprint composition, and cross-component coordination. This enhancement extracts only the module-level operational behavior concept as `#Directive`. The two designs are compatible, not competing.

### Enhancement 007 (Draft, not superseded)

Enhancement 007's `#Offer` design is the supply side of 006. Not relevant to this enhancement.
