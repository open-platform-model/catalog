# v1alpha1 — Definition Index

CUE module: `opmodel.dev/k8up/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- backup/
+-- schemas/
```

## Resources

| Path | Name | Description |
|---|---|---|
| `resources/backup/schedule.cue` | `#Schedule` | A K8up Schedule (recurring backup, check, and prune) |
| `resources/backup/pre_backup_pod.cue` | `#PreBackupPod` | A K8up PreBackupPod (runs before each backup for consistency) |
| `resources/backup/backup.cue` | `#Backup` | A K8up one-off Backup |
| `resources/backup/restore.cue` | `#Restore` | A K8up Restore (restore from restic repository) |

## Schemas

| Path | Name | Description |
|---|---|---|
| `schemas/backup.cue` | `#ScheduleSchema` | Open schema for K8up Schedule CR spec |
| `schemas/backup.cue` | `#PreBackupPodSchema` | Open schema for K8up PreBackupPod CR spec |
| `schemas/backup.cue` | `#BackupSchema` | Open schema for K8up Backup CR spec |
| `schemas/backup.cue` | `#RestoreSchema` | Open schema for K8up Restore CR spec |

## Transformers

| Path | Name | Description |
|---|---|---|
| `providers/kubernetes/transformers/schedule_transformer.cue` | `#ScheduleTransformer` | Passes K8up Schedule through with OPM context |
| `providers/kubernetes/transformers/pre_backup_pod_transformer.cue` | `#PreBackupPodTransformer` | Passes K8up PreBackupPod through with OPM context |
| `providers/kubernetes/transformers/backup_transformer.cue` | `#BackupTransformer` | Passes K8up Backup through with OPM context |
| `providers/kubernetes/transformers/restore_transformer.cue` | `#RestoreTransformer` | Passes K8up Restore through with OPM context |
