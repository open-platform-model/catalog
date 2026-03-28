# Design: Two-Trait Approach

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Design Goals

- Provide a reusable, generic backup trait that any OPM module can adopt
- Separate the backup contract (what to back up, where, when) from the implementation (K8up, Velero, etc.)
- Separate the pre-backup hook concern from the backup scheduling concern
- Support diverse pre-backup hooks without the trait knowing application specifics
- Keep per-module S3 backends (separate buckets per application)
- Trait attaches to the component it protects — co-located with the data it backs up

---

## Non-Goals (v1)

- Restore trait (manual restore via K8up Restore CR remains the workflow)
- Pod security context configuration for backup/restore pods
- Environment-level backend defaults (each trait instance is fully self-contained)
- Automatic PVC discovery from the component's workload spec

---

## Two-Trait Split

Backup is decomposed into two independent, composable traits:

### `#BackupTrait` — "Protect this component's data"

Declares the backup intent: what to back up, where to store it, on what schedule, and how long to retain it. This trait is provider-agnostic — it does not reference K8up, Restic, or any implementation detail.

### `#PreBackupHookTrait` — "Prepare before backing up"

Declares a preparation step that must complete before the backup runs. This is a separate trait because:

- Many components need no hook at all (static files, configuration data)
- Hook logic requires application-specific knowledge that the backup trait should not care about
- The Kubernetes transformer generates a K8up PreBackupPod only when this trait is present

### Composition Rules

- `#BackupTrait` alone: valid — generates backup schedule only
- `#BackupTrait` + `#PreBackupHookTrait`: valid — generates schedule + pre-backup hook
- `#PreBackupHookTrait` alone: invalid — nothing to hook into (enforced by transformer via `requiredTraits`)

---

## `#BackupTrait` Schema

```cue
#BackupSchema: {
    // Target PVC to back up. Required — explicit over implicit.
    pvcName!: string

    // Backup schedule (cron syntax)
    schedule: *"0 2 * * *" | string

    // Storage backend
    backend: {
        s3: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }
        repoPassword!: schemas.#Secret
    }

    // Retention policy
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // Maintenance schedules
    checkSchedule: *"0 4 * * 0" | string
    pruneSchedule: *"0 5 * * 0" | string
}
```

### Design Notes

- **`pvcName` is explicit**: The trait requires the PVC name rather than inferring it from the component's workload spec. This avoids coupling the backup trait to workload resource internals, and supports backing up components that are not workloads (ConfigMaps, Secrets with associated PVCs).
- **`backend.s3`**: S3 is the only backend in v1. The `backend` wrapper allows adding other backends (GCS, Azure Blob) without breaking the schema.
- **`schemas.#Secret`**: Reuses the existing OPM secret reference type for credential handling.
- **No K8up-specific fields**: The schema is provider-agnostic. Fields like `podSecurityContext` or `resticOptions` belong in the transformer or a future extension.

---

## `#PreBackupHookTrait` Schema

```cue
#PreBackupHookSchema: {
    // Container image for the hook pod
    image!: string

    // Command to execute
    command!: [...string]

    // Volume mount for accessing the PVC data
    volumeMount?: {
        pvcName!:  string
        mountPath: *"/data" | string
    }
}
```

### Design Notes

- **Simple contract**: image + command + optional volume mount covers all known use cases (SQLite checkpoint, RCON, pg_dump, custom scripts).
- **Single command**: K8up's PreBackupPod model is a single pod. Multi-step preparation is expressed as a shell script within the command array (e.g., `["sh", "-c", "cmd1 && cmd2 && cmd3"]`).
- **Optional volume mount**: Not all hooks need PVC access. An RCON hook talks to the application over the network and needs no volume. When `volumeMount` is set, the transformer mounts the specified PVC into the hook pod.
- **No `volumeMount` default derivation**: The hook's PVC may differ from the backup target PVC (e.g., hook checkpoints a database on PVC-A, backup captures PVC-B which contains the WAL-checkpointed files). Keeping them independent avoids incorrect assumptions.

---

## Trait Definitions

### `#BackupTrait`

```cue
#BackupTrait: prim.#Trait & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/traits/data"
        version:     "v1"
        name:        "backup"
        description: "Declares periodic backup for a component's persistent data"
        labels: {
            "trait.opmodel.dev/category": "data"
        }
    }

    // Applies to any component — workloads, data stores, config
    appliesTo: [...]

    spec: close({backup: #BackupSchema})
}
```

### `#PreBackupHookTrait`

```cue
#PreBackupHookTrait: prim.#Trait & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/traits/data"
        version:     "v1"
        name:        "pre-backup-hook"
        description: "Declares a preparation command to run before each backup"
        labels: {
            "trait.opmodel.dev/category": "data"
        }
    }

    appliesTo: [...]

    spec: close({preBackupHook: #PreBackupHookSchema})
}
```

---

## File Layout

```
catalog/opm/v1alpha1/
  schemas/
    data.cue                          # Add #BackupSchema, #PreBackupHookSchema
  traits/
    data/
      backup.cue                      # #BackupTrait, #Backup (component mixin)
      pre_backup_hook.cue             # #PreBackupHookTrait, #PreBackupHook (component mixin)
  providers/
    kubernetes/
      transformers/
        backup_transformer.cue        # K8up Schedule + PreBackupPod generation
        backup_transformer_tests.cue  # Transformer tests
```
