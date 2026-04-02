# Design — `#Directive` Primitive: Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Design Goals

- Introduce `#Directive` as a primitive type within `#Policy`, alongside `#PolicyRule`
- Directives describe operational behavior the platform executes — no enforcement semantics
- Define `#BackupDirective` as a combined backup + pre-backup hook + restore schema
- Transformers generate K8up resources from directives
- CLI reads directives to browse snapshots and execute restores
- Provider-agnostic contract — K8up is an implementation detail in the transformer

## Non-Goals (v1)

- Component-level placement or Blueprint composition (that's enhancement 006's `#Claim`)
- Data dependency claims (Postgres, Redis connections)
- Cross-module backup coordination
- Environment-level S3 backend defaults
- Automatic PVC discovery from workload specs

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
        name!:        t.#NameType         // Example: "backup"
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
| Examples | Encryption policy, resource limits | Backup scheduling, restore procedures |
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

A `#Policy` may contain only `#rules`, only `#directives`, or both. This is valid — a policy grouping backup directives with no governance rules is a natural pattern.

---

## `#BackupDirective`

A single combined directive covering backup scheduling, optional pre-backup hooks, and optional restore procedures. Combined because:

- At the policy level there is no independent composition pressure (unlike component-level traits)
- Restore is tightly coupled to backup (same S3 backend, same repo, same PVC targets)
- Module authors define all three concerns together

```cue
#BackupDirective: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/directives/data"
        version:     "v1"
        name:        "backup"
        description: "Backup scheduling, pre-backup hooks, and restore for persistent data"
    }
    #spec: close({backup: #BackupDirectiveSchema})
}
```

### `#BackupDirectiveSchema`

```cue
#BackupDirectiveSchema: {
    // What to back up — one or more PVC targets
    targets!: [...{
        pvcName!:  string          // Explicit PVC name (not inferred from workload)
        mountPath: *"/data" | string // Mount path for Restic file discovery
    }]

    // Backup schedule (cron syntax)
    schedule:      *"0 2 * * *" | string  // Default: 2 AM daily
    checkSchedule: *"0 4 * * 0" | string  // Default: 4 AM weekly
    pruneSchedule: *"0 5 * * 0" | string  // Default: 5 AM weekly

    // Retention policy
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // Storage backend — release-provided
    backend!: {
        s3: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }
        repoPassword!: schemas.#Secret
    }

    // Optional pre-backup hook — runs before backup starts
    preBackupHook?: {
        image!:   string          // Container image for the hook
        command!: [...string]     // Command to execute
        volumeMount?: {
            pvcName!:  string            // PVC to mount (may differ from backup target)
            mountPath: *"/data" | string
        }
    }

    // Optional restore description — read by CLI for restore execution
    restore?: {
        healthCheck?: {
            path!: string   // HTTP path to check after restore
            port!: int      // Port to check
        }
        requiresScaleDown: *true | bool // Whether workload must be scaled to 0 during restore
    }
}
```

### Design Notes

**`targets` uses explicit `pvcName`**: Avoids coupling to workload internals. The module author knows which PVCs contain data worth protecting. Supports components that own multiple PVCs or non-workload components.

**`backend.s3` wrapper**: Allows adding `backend.gcs`, `backend.azure` in future versions without breaking the schema.

**`schemas.#Secret` for credentials**: Reuses OPM's existing secret type, supporting both inline values and secret references (`{secretName, remoteKey}`).

**`preBackupHook` is optional and inline**: Many backups need no hook (static files, configuration). When needed, the hook is defined inline rather than as a separate directive because it shares the backup's lifecycle and targets.

**`preBackupHook.volumeMount` may differ from backup target**: The hook may access a different PVC than what is being backed up (e.g., hook reads a database PVC to run checkpoint, backup captures a different data PVC).

**`restore` is optional and descriptive**: Not all modules need structured restore. When present, the CLI reads it to automate the restore procedure (scale down, create K8up Restore CR, verify health, scale up). When absent, restore is manual.

---

## Module Integration Overview

Module authors add backup directives to `#policies`. Release authors provide environment-specific values (S3 credentials, bucket names).

```cue
#Module & {
    #components: {
        jellyfin: workload_blueprints.#StatefulWorkload & {
            spec: statefulWorkload: { /* ... */ }
        }
    }

    #policies: {
        "jellyfin-backup": policy.#Policy & {
            appliesTo: components: [#components.jellyfin]

            #directives: {
                (data_directives.#BackupDirective.metadata.fqn): data_directives.#BackupDirective & {
                    #spec: backup: {
                        targets: [{
                            pvcName: "jellyfin-config"
                            mountPath: "/config"
                        }]
                        backend: #config.backup.backend
                        schedule: #config.backup.schedule

                        preBackupHook: {
                            image: "alpine:3.21"
                            command: ["sh", "-c", """
                                sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                                sqlite3 /config/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE)'
                                """]
                            volumeMount: {
                                pvcName: "jellyfin-config"
                                mountPath: "/config"
                            }
                        }

                        restore: {
                            healthCheck: {
                                path: "/health"
                                port: 8096
                            }
                            requiresScaleDown: true
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

Enhancement 004's component-level `#BackupTrait` + `#PreBackupHookTrait` design is correct mechanically but at the wrong scope. This enhancement moves backup to module-level `#Policy` where it belongs. The transformer output (K8up Schedule, PreBackupPod) is largely the same.

### Enhancement 006 (Draft, not superseded)

Enhancement 006's `#Claim` + `#Orchestration` design is broader — it handles data dependencies (Postgres, Redis), Blueprint composition, and cross-component coordination. This enhancement extracts only the module-level operational behavior concept as `#Directive`. If 006 is implemented later, `#BackupDirective` could either remain as-is or migrate to a `#BackupClaim` + restore orchestration.

The key difference: `#Directive` is simpler. No component-level placement, no Blueprint composition, no second rendering pipeline. It extends `#Policy` with a new map field and extends `#Transformer` with directive matching — minimal changes to existing infrastructure.

### Enhancement 007 (Draft, not superseded)

Enhancement 007's `#Offer` design is the supply side of 006. Not relevant to this enhancement — `#Directive` does not need an offer/claim pairing because it describes what the module needs the platform to do, not what another module can provide.
