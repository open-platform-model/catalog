# Module Integration — Unified K8up Backup Directive

## Responsibility Split

| Concern | Owner | Where |
|---|---|---|
| Which components are backed up | Module author | `Policy.appliesTo.components` |
| How to quiesce a component before backup | Module author | `#PreBackupHookTrait` on the component |
| Restore order and per-component restore procedure | Module author | `restore` map in the directive (definition order) |
| S3 endpoint, bucket, credentials | Release author | `release.cue` → `#config.backup` |
| Restic/Kopia repo password | Release author | `release.cue` → `#config.backup` |
| Backup schedule | Release author | `release.cue` → `#config.backup` |
| Retention policy | Release author (with module defaults) | `release.cue` or module defaults |

---

## Module Author Experience

### Jellyfin — SQLite hook + restore

```cue
import (
    policy "opmodel.dev/core/v1alpha1/policy@v1"
    exp_directives "opmodel.dev/opm_experiments/v1alpha1/directives@v1"
    exp_traits "opmodel.dev/opm_experiments/v1alpha1/traits@v1"
    workload_blueprints "opmodel.dev/opm/v1alpha1/blueprints@v1"
)

#Module & {
    #components: {
        jellyfin: workload_blueprints.#StatefulWorkload & {
            spec: statefulWorkload: container: {
                image: repository: "linuxserver/jellyfin"
                // ...
            }

            // Component declares its quiescing procedure once
            #traits: {
                (exp_traits.#PreBackupHookTrait.metadata.fqn): exp_traits.#PreBackupHookTrait & {
                    spec: preBackupHook: {
                        image: "alpine:3.21"
                        command: ["sh", "-c", """
                            sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                            sqlite3 /config/data/jellyfin.db  'PRAGMA wal_checkpoint(TRUNCATE)'
                            """]
                        volumeMount: {
                            volume:    "config"
                            mountPath: "/config"
                        }
                    }
                }
            }
        }
    }

    #policies: {
        "backup": policy.#Policy & {
            appliesTo: components: [#components.jellyfin]

            #directives: {
                (exp_directives.#K8upBackupDirective.metadata.fqn): exp_directives.#K8upBackupDirective & {
                    #spec: k8upBackup: {
                        schedule:  #config.backup.schedule
                        retention: #config.backup.retention

                        repository: #config.backup.repository

                        restore: {
                            jellyfin: {
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

    #config: {
        backup?: {
            schedule!: string
            repository!: {
                format: *"restic" | "kopia"
                s3!: {
                    endpoint!:        string
                    bucket!:          string
                    accessKeyID!:     _
                    secretAccessKey!: _
                }
                password!: _
            }
            retention: {
                keepDaily:   *7 | int
                keepWeekly:  *4 | int
                keepMonthly: *6 | int
            }
        }
    }
}
```

### Minecraft — RCON hook, no volume mount

Hook runs over the network; no mount needed. Same directive shape, different trait configuration.

```cue
#components: {
    minecraft: workload_blueprints.#StatefulWorkload & {
        // ... workload spec ...
        #traits: {
            (exp_traits.#PreBackupHookTrait.metadata.fqn): exp_traits.#PreBackupHookTrait & {
                spec: preBackupHook: {
                    image: "itzg/mc-monitor:0.12"
                    command: [
                        "mc-monitor", "execute-rcon",
                        "--host", "localhost",
                        "--port", "25575",
                        "--command", "save-all flush",
                    ]
                    // No volumeMount — RCON talks over the network
                }
            }
        }
    }
}

#policies: {
    "backup": policy.#Policy & {
        appliesTo: components: [#components.minecraft]

        #directives: {
            (exp_directives.#K8upBackupDirective.metadata.fqn): exp_directives.#K8upBackupDirective & {
                #spec: k8upBackup: {
                    schedule:   #config.backup.schedule
                    repository: #config.backup.repository

                    restore: {
                        minecraft: { requiresScaleDown: true }
                    }
                }
            }
        }
    }
}
```

### Static files — no hook, no health check

```cue
#policies: {
    "backup": policy.#Policy & {
        appliesTo: components: [#components.app]

        #directives: {
            (exp_directives.#K8upBackupDirective.metadata.fqn): exp_directives.#K8upBackupDirective & {
                #spec: k8upBackup: {
                    schedule:   #config.backup.schedule
                    repository: #config.backup.repository

                    restore: {
                        app: {
                            requiresScaleDown: true
                            // No healthCheck — manual verification
                        }
                    }
                }
            }
        }
    }
}
```

### Multi-component — app + database, restore order matters

```cue
#components: {
    database: workload_blueprints.#StatefulWorkload & {
        // ...
        #traits: {
            (exp_traits.#PreBackupHookTrait.metadata.fqn): exp_traits.#PreBackupHookTrait & {
                spec: preBackupHook: {
                    image: "postgres:16-alpine"
                    command: ["pg_dump", "-U", "postgres", "-f", "/backup/dump.sql"]
                    volumeMount: {
                        volume:    "data"
                        mountPath: "/var/lib/postgresql/data"
                    }
                }
            }
        }
    }
    app: workload_blueprints.#StatefulWorkload & { /* ... */ }
}

#policies: {
    "backup": policy.#Policy & {
        appliesTo: components: [#components.app, #components.database]

        #directives: {
            (exp_directives.#K8upBackupDirective.metadata.fqn): exp_directives.#K8upBackupDirective & {
                #spec: k8upBackup: {
                    schedule:   #config.backup.schedule
                    repository: #config.backup.repository

                    // Definition order = restore order.
                    // database restored first, then app.
                    restore: {
                        database: {
                            requiresScaleDown: true
                        }
                        app: {
                            requiresScaleDown: false
                            healthCheck: {
                                path: "/healthz"
                                port: 8080
                            }
                        }
                    }
                }
            }
        }
    }
}
```

---

## Release Author Experience

One `#config.backup` block supplies all environment-specific values. Both the K8up Schedule transformer (via `repository`) and the CLI (via the same `repository`) read from it.

```cue
// releases/kind_opm_dev/jellyfin/release.cue
values: {
    backup: {
        schedule: "0 2 * * *"
        repository: {
            format: "restic"
            s3: {
                endpoint: "http://garage-garage.garage.svc:3900"
                bucket:   "jellyfin-backups"
                accessKeyID: {
                    secretName: "jellyfin-backup-s3"
                    remoteKey:  "access-key-id"
                }
                secretAccessKey: {
                    secretName: "jellyfin-backup-s3"
                    remoteKey:  "secret-access-key"
                }
            }
            password: {
                secretName: "jellyfin-backup-restic"
                remoteKey:  "password"
            }
        }
        retention: {
            keepDaily:   7
            keepWeekly:  4
            keepMonthly: 6
        }
    }
}
```

---

## Migration Path

For modules currently using direct K8up catalog imports:

1. Add `#K8upBackupDirective` to `#policies` using the unified schema. Pull schedule/retention/repository from existing `#config.backup`.
2. Remove old K8up Schedule and PreBackupPod components from `#components`.
3. Move pre-backup hook logic to a `#PreBackupHookTrait` on the component that needs quiescing.
4. Add the restore procedure (`restore` block) alongside the backup fields in the same directive.
5. Remove the K8up catalog dependency from `cue.mod/module.cue`; add `opmodel.dev/opm_experiments/v1alpha1@v1`.
6. Update release configs: rename `backend` → `repository`, fold `repoPassword` → `password`.

Migration is per-module and incremental. A module with no backup policy is unaffected.

---

## Conditional Backup

Backup is optional. When the release omits `#config.backup`, the module does not emit the backup policy:

```cue
#policies: {
    if #config.backup != _|_ {
        "backup": policy.#Policy & {
            // ... directive ...
        }
    }
}
```
