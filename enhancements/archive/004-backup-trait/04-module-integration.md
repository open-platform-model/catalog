# Module Integration

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Overview

This document describes how module authors consume the backup traits and how release authors configure them per environment.

---

## Module-Side: Defining Backup Capability

A module author adds backup support by applying the traits to the component that owns the data:

```cue
import (
    data_traits "opmodel.dev/opm/v1alpha1/traits/data@v1"
)

#components: {
    jellyfin: {
        workload_blueprints.#StatefulWorkload
        spec: statefulWorkload: { ... }

        // Opt in to backup (conditional on config)
        if #config.backup != _|_ {
            data_traits.#Backup
            spec: backup: {
                pvcName: #config.backup.pvcName
                backend: #config.backup.backend
                schedule: #config.backup.schedule
                retention: #config.backup.retention
                checkSchedule: #config.backup.checkSchedule
                pruneSchedule: #config.backup.pruneSchedule
            }

            // Pre-backup hook for SQLite consistency
            data_traits.#PreBackupHook
            spec: preBackupHook: {
                image: "alpine:3.21"
                command: ["sh", "-c", """
                    sqlite3 /data/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                    sqlite3 /data/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE)'
                    """]
                volumeMount: {
                    pvcName: #config.backup.pvcName
                    mountPath: "/data"
                }
            }
        }
    }
}
```

### Key Points

- The trait is applied to the same component it protects — co-location makes the relationship explicit
- The pre-backup hook is defined in the module because it requires application-specific knowledge (which databases exist, what commands to run)
- Environment-specific values (S3 endpoint, credentials, bucket) flow through `#config.backup` from the release

---

## Release-Side: Providing Environment Config

The release author fills in the environment-specific values:

```cue
// releases/kind_opm_dev/jellyfin/release.cue
values: {
    backup: {
        pvcName: "jellyfin-jellyfin-config"
        backend: {
            s3: {
                endpoint: "http://garage-garage.garage.svc:3900"
                bucket:   "jellyfin-backups"
                accessKeyID:     {secretName: "jellyfin-backup-s3", remoteKey: "access-key-id"}
                secretAccessKey: {secretName: "jellyfin-backup-s3", remoteKey: "secret-access-key"}
            }
            repoPassword: {secretName: "jellyfin-backup-restic", remoteKey: "password"}
        }
        retention: {keepDaily: 7, keepWeekly: 4, keepMonthly: 6}
    }
}
```

### Responsibility Split

| Concern | Owner | Where |
| --- | --- | --- |
| Which PVC to back up | Release author | `release.cue` via `values.backup.pvcName` |
| Pre-backup commands | Module author | `components.cue` (hardcoded or config-driven) |
| S3 endpoint and credentials | Release author | `release.cue` via `values.backup.backend` |
| S3 bucket name | Release author | `release.cue` via `values.backup.backend.s3.bucket` |
| Retention policy | Release author (with module defaults) | `release.cue` or module defaults |
| Backup schedule | Release author (with module defaults) | `release.cue` or module defaults |

---

## Example: Minecraft (RCON Hook, No Volume Mount)

```cue
#components: {
    minecraft: {
        workload_blueprints.#StatefulWorkload
        spec: statefulWorkload: { ... }

        if #config.backup != _|_ {
            data_traits.#Backup
            spec: backup: #config.backup

            // RCON hook — no volume mount needed, talks to app over network
            data_traits.#PreBackupHook
            spec: preBackupHook: {
                image: "itzg/rcon-cli:latest"
                command: ["sh", "-c", "rcon-cli save-all && rcon-cli save-off"]
                // No volumeMount — RCON communicates over the network
            }
        }
    }
}
```

---

## Example: Static Files (No Hook)

```cue
#components: {
    "file-server": {
        workload_blueprints.#StatelessWorkload
        spec: statelessWorkload: { ... }

        // Backup with no hook — just back up the PVC as-is
        if #config.backup != _|_ {
            data_traits.#Backup
            spec: backup: #config.backup
            // No #PreBackupHook — not needed for static files
        }
    }
}
```

---

## Adding Backup Browsing with Hatch

Module authors can optionally add a [Hatch](../../../hatch/) component to provide an authenticated web UI for browsing backup snapshots. Hatch is a separate workload component — not a trait — so it requires a conscious decision by the module author.

See [06-backup-browser.md](06-backup-browser.md) for the full design rationale.

### Module-Side: Adding a Hatch Component

```cue
#components: {
    jellyfin: {
        workload_blueprints.#StatefulWorkload
        spec: statefulWorkload: { ... }

        // Backup trait on the protected component
        if #config.backup != _|_ {
            data_traits.#Backup
            spec: backup: {
                pvcName:       #config.backup.pvcName
                backend:       #config.backup.backend
                schedule:      #config.backup.schedule
                retention:     #config.backup.retention
                checkSchedule: #config.backup.checkSchedule
                pruneSchedule: #config.backup.pruneSchedule
            }

            data_traits.#PreBackupHook
            spec: preBackupHook: {
                image: "alpine:3.21"
                command: ["sh", "-c", """
                    sqlite3 /data/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                    sqlite3 /data/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE)'
                    """]
                volumeMount: {
                    pvcName:   #config.backup.pvcName
                    mountPath: "/data"
                }
            }
        }
    }

    // Hatch backup browser — separate component, conscious opt-in
    if #config.hatch != _|_ if #config.hatch.enabled {
        hatch: {
            workload_blueprints.#StatelessWorkload
            traits_network.#Expose

            spec: {
                statelessWorkload: container: {
                    name:  "hatch"
                    image: #config.hatch.image
                    args: ["--config", "/etc/hatch/config.yaml"]
                }

                expose: ports: http: {
                    targetPort:  8080
                    exposedPort: 8080
                }
            }
        }
    }
}
```

### Release-Side: Providing Hatch Config

The release author enables Hatch and provides the image reference. The S3 credentials and repo password are shared with the backup trait via `values.backup.backend`:

```cue
// releases/kind_opm_dev/jellyfin/release.cue
values: {
    backup: {
        pvcName: "jellyfin-jellyfin-config"
        backend: {
            s3: {
                endpoint:        "http://garage-garage.garage.svc:3900"
                bucket:          "jellyfin-backups"
                accessKeyID:     {secretName: "jellyfin-backup-s3", remoteKey: "access-key-id"}
                secretAccessKey: {secretName: "jellyfin-backup-s3", remoteKey: "secret-access-key"}
            }
            repoPassword: {secretName: "jellyfin-backup-restic", remoteKey: "password"}
        }
        retention: {keepDaily: 7, keepWeekly: 4, keepMonthly: 6}
    }
    hatch: {
        enabled: true
        image: {
            repository: "ghcr.io/opmodel/hatch"
            tag:        "latest"
        }
    }
}
```

The Hatch container receives S3 credentials and the repo password via Kubernetes Secret volume mounts. Its YAML config references the mounted files. Config can be delivered as a ConfigMap or as an inline container argument (`--config-yaml`), following the Envoy Proxy pattern.

### Updated Responsibility Split

| Concern | Owner | Where |
| --- | --- | --- |
| Backup browser enablement | Module author + Release author | Module defines the component; release sets `hatch.enabled` |
| Hatch image | Release author | `release.cue` via `values.hatch.image` |
| Hatch config delivery | Module author | ConfigMap or inline `--config` / `--config-yaml` argument |
| Backup browsing credentials | Release author (shared with backup) | Same `values.backup.backend` used by the backup trait |

---

## Migration Path

Existing modules (Jellyfin, Seerr) currently import the K8up catalog directly and generate K8up CRs in their `components.cue`. Migration to the trait-based approach:

1. Replace K8up catalog imports with OPM trait imports
2. Replace manual K8up Schedule/PreBackupPod component definitions with trait application
3. Adapt `#config.backup` schema to match the new `#BackupSchema` structure
4. Remove the K8up catalog dependency from the module's `cue.mod/module.cue`
5. Update release configs to match the new schema (minor field name changes)

The migration is per-module, non-breaking (no runtime behavior change), and can be done incrementally.
