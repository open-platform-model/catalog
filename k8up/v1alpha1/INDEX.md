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

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | K8upKubernetesProvider transforms K8up backup components to Kubernetes native resources |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#BackupTransformer` | `providers/kubernetes/transformers/backup_transformer.cue` | #BackupTransformer passes K8up Backup resources through with OPM context applied (name prefix, namespace, labels) |
| `#PreBackupPodTransformer` | `providers/kubernetes/transformers/pre_backup_pod_transformer.cue` | #PreBackupPodTransformer passes K8up PreBackupPod resources through with OPM context applied (name prefix, namespace, labels) |
| `#RestoreTransformer` | `providers/kubernetes/transformers/restore_transformer.cue` | #RestoreTransformer passes K8up Restore resources through with OPM context applied (name prefix, namespace, labels) |
| `#ScheduleTransformer` | `providers/kubernetes/transformers/schedule_transformer.cue` | #ScheduleTransformer passes K8up Schedule resources through with OPM context applied (name prefix, namespace, labels) |

---

## Resources

### backup

| Definition | File | Description |
|---|---|---|
| `#Backup` | `resources/backup/backup.cue` |  |
| `#BackupDefaults` | `resources/backup/backup.cue` |  |
| `#BackupResource` | `resources/backup/backup.cue` |  |
| `#PreBackupPod` | `resources/backup/pre_backup_pod.cue` |  |
| `#PreBackupPodDefaults` | `resources/backup/pre_backup_pod.cue` |  |
| `#PreBackupPodResource` | `resources/backup/pre_backup_pod.cue` |  |
| `#Restore` | `resources/backup/restore.cue` |  |
| `#RestoreDefaults` | `resources/backup/restore.cue` |  |
| `#RestoreResource` | `resources/backup/restore.cue` |  |
| `#Schedule` | `resources/backup/schedule.cue` |  |
| `#ScheduleDefaults` | `resources/backup/schedule.cue` |  |
| `#ScheduleResource` | `resources/backup/schedule.cue` |  |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#BackupSchema` | `schemas/backup.cue` | #BackupSchema accepts the full K8up Backup spec |
| `#PreBackupPodSchema` | `schemas/backup.cue` | #PreBackupPodSchema accepts the full K8up PreBackupPod spec |
| `#RestoreSchema` | `schemas/backup.cue` | #RestoreSchema accepts the full K8up Restore spec |
| `#ScheduleSchema` | `schemas/backup.cue` | #ScheduleSchema accepts the full K8up Schedule spec |

---

