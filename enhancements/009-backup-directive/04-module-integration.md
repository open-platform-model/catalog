# Module Integration — Backup & Restore Directives

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Responsibility Split

| Concern | Owner | Where |
|---------|-------|-------|
| Which components to back up | Module author | `targets` keys in K8up directive |
| Which resources to protect per component | Module author | `volumes`/`configMaps`/`secrets` in targets |
| Pre-backup commands | Module author | `preBackupHook` per component target |
| Restore order and procedures | Module author | `components` definition order in restore directive |
| S3 endpoint & credentials | Release author | `release.cue` values |
| S3 bucket name | Release author | `release.cue` values |
| Retention policy | Release author (with module defaults) | `release.cue` or module defaults |
| Backup schedule | Release author | `release.cue` values |

---

## Module Author Experience

### Jellyfin — SQLite hook + restore

```cue
import (
    policy "opmodel.dev/core/v1alpha1/policy@v1"
    k8up_directives "opmodel.dev/opm/v1alpha1/directives/data@v1"
    data_directives "opmodel.dev/opm/v1alpha1/directives/data@v1"
    workload_blueprints "opmodel.dev/opm/v1alpha1/blueprints@v1"
)

#Module & {
    #components: {
        jellyfin: workload_blueprints.#StatefulWorkload & {
            spec: statefulWorkload: container: {
                image: repository: "linuxserver/jellyfin"
                // ...
            }
        }
    }

    #policies: {
        "backup": policy.#Policy & {
            appliesTo: components: [#components.jellyfin]

            #directives: {
                // K8up transformer generates Schedule + PreBackupPod
                (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective & {
                    #spec: k8upBackup: {
                        schedule:  #config.backup.schedule
                        backend:   #config.backup.backend
                        retention: #config.backup.retention

                        targets: {
                            jellyfin: {
                                volumes: {
                                    config: {
                                        backupPath: "/data"
                                    }
                                }

                                preBackupHook: {
                                    image: "alpine:3.21"
                                    command: ["sh", "-c", """
                                        sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                                        sqlite3 /config/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE)'
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

    #config: {
        backup?: {
            schedule!: string
            backend!: {
                s3: {
                    endpoint!:        string
                    bucket!:          string
                    accessKeyID!:     _
                    secretAccessKey!: _
                }
                repoPassword!: _
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

```cue
#policies: {
    "backup": policy.#Policy & {
        appliesTo: components: [#components.minecraft]

        #directives: {
            (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective & {
                #spec: k8upBackup: {
                    schedule: #config.backup.schedule
                    backend:  #config.backup.backend

                    targets: {
                        minecraft: {
                            volumes: {
                                data: {}  // backupPath defaults to "/"
                            }

                            preBackupHook: {
                                image: "itzg/mc-monitor:0.12"
                                command: ["mc-monitor", "execute-rcon",
                                    "--host", "localhost",
                                    "--port", "25575",
                                    "--command", "save-all flush",
                                ]
                                // No volumeMount — RCON talks to the app over network
                            }
                        }
                    }
                }
            }

            (data_directives.#RestoreDirective.metadata.fqn): data_directives.#RestoreDirective & {
                #spec: restore: {
                    repository: {
                        s3:           #config.backup.backend.s3
                        repoPassword: #config.backup.backend.repoPassword
                    }
                    components: {
                        minecraft: {
                            volumes: { data: {} }
                            requiresScaleDown: true
                        }
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
            (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective & {
                #spec: k8upBackup: {
                    schedule: #config.backup.schedule
                    backend:  #config.backup.backend
                    targets: {
                        app: {
                            volumes: { uploads: {} }
                        }
                    }
                }
            }

            (data_directives.#RestoreDirective.metadata.fqn): data_directives.#RestoreDirective & {
                #spec: restore: {
                    repository: {
                        s3:           #config.backup.backend.s3
                        repoPassword: #config.backup.backend.repoPassword
                    }
                    components: {
                        app: {
                            volumes: { uploads: {} }
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

### Multi-component — app + database (restore order matters)

```cue
#policies: {
    "backup": policy.#Policy & {
        appliesTo: components: [#components.app, #components.database]

        #directives: {
            (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective & {
                #spec: k8upBackup: {
                    schedule: #config.backup.schedule
                    backend:  #config.backup.backend

                    targets: {
                        database: {
                            volumes: { data: {} }
                            preBackupHook: {
                                image: "postgres:16-alpine"
                                command: ["pg_dump", "-U", "postgres", "-f", "/backup/dump.sql"]
                                volumeMount: {
                                    volume:    "data"
                                    mountPath: "/var/lib/postgresql/data"
                                }
                            }
                        }
                        app: {
                            volumes: { uploads: {} }
                            configMaps: { "app-config": {} }
                        }
                    }
                }
            }

            (data_directives.#RestoreDirective.metadata.fqn): data_directives.#RestoreDirective & {
                #spec: restore: {
                    repository: {
                        s3:           #config.backup.backend.s3
                        repoPassword: #config.backup.backend.repoPassword
                    }
                    // Definition order = restore order
                    // Database restored first, then app
                    components: {
                        database: {
                            volumes: { data: {} }
                            requiresScaleDown: true
                        }
                        app: {
                            volumes: { uploads: {} }
                            configMaps: { "app-config": {} }
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

The release author provides environment-specific values. Both directives reference `#config.backup`:

```cue
// releases/kind_opm_dev/jellyfin/release.cue
values: {
    backup: {
        schedule: "0 2 * * *"
        backend: {
            s3: {
                endpoint: "http://garage-garage.garage.svc:3900"
                bucket: "jellyfin-backups"
                accessKeyID: {
                    secretName: "jellyfin-backup-s3"
                    remoteKey:  "access-key-id"
                }
                secretAccessKey: {
                    secretName: "jellyfin-backup-s3"
                    remoteKey:  "secret-access-key"
                }
            }
            repoPassword: {
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

1. Add `#K8upBackupDirective` to `#policies` with K8up-specific config from current `#config.backup`
2. Add `#RestoreDirective` to the same policy with repository connection and restore procedures
3. Move pre-backup hook logic from K8up PreBackupPod component to per-component `preBackupHook`
4. Map PVC names to volume names in `targets[component].volumes`
5. Remove K8up Schedule and PreBackupPod component definitions from `#components`
6. Remove K8up catalog dependency from `cue.mod/module.cue`
7. Update release configs (add `schedule` to values, minor field name adjustments)

Migration is per-module, non-breaking, and incremental.

---

## Conditional Backup

Backup is optional. When `#config.backup` is not provided in the release, no directives are present:

```cue
#policies: {
    if #config.backup != _|_ {
        "backup": policy.#Policy & {
            // ... both directives ...
        }
    }
}
```
