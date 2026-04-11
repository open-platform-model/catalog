# Backup Browser

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Overview

This document describes how module authors can provide an authenticated web UI for browsing backup snapshots, navigating their contents, and downloading backup data. The recommended implementation is [Hatch](../../../hatch/), a lightweight web sidecar already designed for file management, extended with backup browsing capabilities.

---

## Problem

The backup trait (`#BackupTrait`) automates backup scheduling, storage, and retention — but provides no way to inspect what was actually backed up. Users who want to verify backup contents, find a specific file version, or download data from a snapshot must use the Restic CLI directly against the S3 backend. This requires:

- SSH or terminal access to a pod with Restic installed
- Knowledge of S3 credentials and repo password
- Familiarity with Restic commands (`snapshots`, `ls`, `dump`)

A simple, authenticated web UI removes this friction for operators and application owners who need visibility into their backup data without CLI expertise.

---

## Design Decision: Separate Component, Not a Trait

The backup browser is deployed as an **independent workload component**, not as a trait on the backed-up component.

### Why not a trait?

Traits enhance existing components — they add behavior to a workload without changing its fundamental nature (e.g., `#Expose` adds a Service, `#BackupTrait` adds a Schedule). A backup browser is a distinct application with its own container, configuration, and network surface. OPM traits do not create new workload components; they modify the output of the component they are attached to.

### Why a separate component?

- **Conscious opt-in**: The module author explicitly adds a Hatch component when backup browsing is desired. Not every backup needs a browser.
- **Independent lifecycle**: The browser can be updated, scaled, or removed without affecting the backup schedule or the backed-up workload.
- **Flexible deployment**: Can run as a sidecar (shared pod) or as a standalone Deployment. The module author chooses based on their needs.
- **No cross-component mutation**: The backup trait on component A does not need to modify or create component B. This avoids architectural complexity that the current transformer model does not support.

---

## Hatch as the Recommended Browser

[Hatch](../../../hatch/) is a lightweight, composable Go + HTMX web interface for data access. It organizes capabilities around **holds** (data sources) and **tools** (cross-cutting capabilities like terminal and log viewer). Each hold has a type that determines its capabilities and UI behavior.

Relevant Hatch features:

- **Composable holds**: Filesystem, S3, and Restic hold types — the UI assembles itself from configured holds ([ADR-012](../../../hatch/adr/012-composable-holds.md))
- **Restic hold**: Read-only browsing of Restic backup snapshots with download support ([ADR-011](../../../hatch/adr/011-backup-browsing.md))
- **Authentication**: Local (username/password with bcrypt), OIDC, and proxy auth ([ADR-005](../../../hatch/adr/005-auth-provider-interface.md))
- **Role-based access control**: admin, editor, viewer roles with per-hold permissions
- **Path sandboxing**: SafeFS prevents path traversal and symlink escapes ([ADR-006](../../../hatch/adr/006-security-model.md))
- **Audit logging**: Structured logging of all access operations
- **Adaptive UI**: Layout adapts to configured holds — sidebar for filesystem/S3, top-nav for Restic-only
- **Minimal footprint**: ~25-30MB container image, <64MB memory
- **CUE config schema**: Type-safe config validation with discriminated unions (`schema/config.cue`)

A Restic hold in Hatch is configured as an entry in the `holds:` array with `type: restic`. The hold is always read-only — `write` and `delete` permissions are forced to `false` by the CUE schema.

---

## Config Sharing Pattern

Both the backup trait and the Hatch component need S3 credentials and the Restic repo password. These are defined once at the release level and referenced by both:

```cue
// module.cue — config schema
#config: {
    backup?: {
        pvcName: string
        backend: {
            s3: {
                endpoint!:        string
                bucket!:          string
                accessKeyID!:     schemas.#Secret
                secretAccessKey!: schemas.#Secret
            }
            repoPassword!: schemas.#Secret
        }
        // ...
    }
    hatch?: {
        enabled: bool | *false
        image:   schemas.#Image
        // ...
    }
}
```

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

The Hatch component receives the S3 credentials and repo password via Kubernetes Secret volume mounts. Its YAML config references the mounted files. The release author writes the credential config once; the CUE wiring ensures both the backup Schedule and Hatch receive the same values.

---

## Module Integration Example

A module author adds Hatch as a conditional standalone component alongside the backed-up workload:

```cue
#components: {
    jellyfin: {
        workload_blueprints.#StatefulWorkload
        // ... main workload spec ...

        // Backup trait on the protected component
        if #config.backup != _|_ {
            data_traits.#Backup
            spec: backup: { /* ... */ }
        }
    }

    // Hatch as a separate component — conscious opt-in
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

The Hatch config YAML is delivered as a ConfigMap or passed inline as a container argument (`--config-yaml`), following the Envoy Proxy pattern. See [Hatch DESIGN.md](../../../hatch/DESIGN.md) for config delivery options.

---

## Deployment Modes

### Standalone Deployment (recommended for backup browsing)

Hatch runs as its own Deployment with a Service. It accesses backup data via S3 — no shared volume needed. This is the simpler option for pure backup browsing.

### Sidecar Deployment

Hatch runs in the same pod as the main workload, sharing a volume. This gives access to both live files (filesystem browsing) and backup snapshots (S3 browsing) from a single UI. Useful when the module author wants Hatch for file management AND backup browsing.

---

## Capabilities

| Capability | Description |
| --- | --- |
| Snapshot listing | List all Restic snapshots with timestamps, tags, and paths |
| Snapshot browsing | Navigate the file tree within a specific snapshot |
| File download | Download individual files from a snapshot |
| Directory download | Download a directory as a tar.gz archive from a snapshot |
| Audit logging | All browse and download operations are logged with user, timestamp, snapshot ID, and path |

---

## Non-Goals

| Non-goal | Rationale |
| --- | --- |
| Restore | Restores are infrequent, high-risk operations. Manual K8up Restore CRs remain the workflow. Deferred. |
| Backup creation | Backup scheduling is the `#BackupTrait`'s responsibility, not the browser's. |
| Backup deletion / pruning | Managed by K8up Schedule retention policies. |
| Multi-repo aggregation (v1) | One Hatch instance browses one Restic repo. Aggregating multiple repos is a future feature. |
