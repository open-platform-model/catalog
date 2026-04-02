# Module Integration — `#Directive` Primitive: Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Responsibility Split

| Concern | Owner | Where |
|---------|-------|-------|
| Which PVCs to back up | Module author | `#policies` directive targets |
| Pre-backup commands | Module author | `preBackupHook` in directive |
| Restore requirements | Module author | `restore` in directive |
| S3 endpoint & credentials | Release author | `release.cue` values |
| S3 bucket name | Release author | `release.cue` values |
| Retention policy | Release author (with module defaults) | `release.cue` or module defaults |
| Backup schedule | Release author (with module defaults) | `release.cue` or module defaults |

---

## Module Author Experience

### Jellyfin — SQLite hook + restore

```cue
import (
    policy "opmodel.dev/core/v1alpha1/policy@v1"
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
        "jellyfin-backup": policy.#Policy & {
            appliesTo: components: [#components.jellyfin]

            #directives: {
                (data_directives.#BackupDirective.metadata.fqn): data_directives.#BackupDirective & {
                    #spec: backup: {
                        targets: [{
                            pvcName: #config.backup.pvcName
                            mountPath: "/config"
                        }]
                        backend:  #config.backup.backend
                        schedule: #config.backup.schedule
                        retention: #config.backup.retention

                        preBackupHook: {
                            image: "alpine:3.21"
                            command: ["sh", "-c", """
                                sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                                sqlite3 /config/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE)'
                                """]
                            volumeMount: {
                                pvcName: #config.backup.pvcName
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

    #config: {
        backup?: {
            pvcName!: string
            schedule: *"0 2 * * *" | string
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
    "minecraft-backup": policy.#Policy & {
        appliesTo: components: [#components.minecraft]

        #directives: {
            (data_directives.#BackupDirective.metadata.fqn): data_directives.#BackupDirective & {
                #spec: backup: {
                    targets: [{
                        pvcName: #config.backup.pvcName
                        mountPath: "/data"
                    }]
                    backend: #config.backup.backend

                    preBackupHook: {
                        image: "itzg/mc-monitor:0.12"
                        command: ["mc-monitor", "execute-rcon",
                            "--host", "localhost",
                            "--port", "25575",
                            "--command", "save-all flush",
                        ]
                        // No volumeMount — RCON talks to the app over network
                    }

                    restore: {
                        requiresScaleDown: true
                    }
                }
            }
        }
    }
}
```

### Static files — no hook, no restore

```cue
#policies: {
    "config-backup": policy.#Policy & {
        appliesTo: components: [#components.app]

        #directives: {
            (data_directives.#BackupDirective.metadata.fqn): data_directives.#BackupDirective & {
                #spec: backup: {
                    targets: [{
                        pvcName: #config.backup.pvcName
                        mountPath: "/data"
                    }]
                    backend: #config.backup.backend
                    // No preBackupHook — just back up the PVC as-is
                    // No restore — manual restore is sufficient
                }
            }
        }
    }
}
```

---

## Release Author Experience

The release author provides environment-specific values. The backup schema fields reference `#config`, which is filled by the release:

```cue
// releases/kind_opm_dev/jellyfin/release.cue
values: {
    backup: {
        pvcName: "jellyfin-jellyfin-config"
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

1. Add `#BackupDirective` to `#policies` with backup config from current `#config.backup`
2. Move pre-backup hook logic from conditional K8up PreBackupPod component to `preBackupHook` field
3. Add `restore` block if structured restore is desired
4. Remove K8up Schedule and PreBackupPod component definitions from `#components`
5. Remove K8up catalog dependency from `cue.mod/module.cue`
6. Update release configs (minor field name adjustments)

Migration is per-module, non-breaking, and incremental. Modules can be migrated one at a time.

---

## Conditional Backup

Backup is optional. When `#config.backup` is not provided in the release, no directive is present and no K8up resources are generated:

```cue
#policies: {
    if #config.backup != _|_ {
        "jellyfin-backup": policy.#Policy & {
            // ... directive definition ...
        }
    }
}
```

This mirrors the current pattern where backup components are conditionally defined based on `#config.backup`.
