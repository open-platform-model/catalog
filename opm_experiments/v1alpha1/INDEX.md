# v1alpha1 — Definition Index

CUE module: `opmodel.dev/opm_experiments/v1alpha1@v1`

---

## Project Structure

```
+-- directives/
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- traits/
```

---

## Directives

| Definition | File | Description |
|---|---|---|
| `#K8upBackup` | `directives/k8up_backup.cue` |  |
| `#K8upBackupDirective` | `directives/k8up_backup.cue` | #K8upBackupDirective: single directive with three sub-blocks |
| `#K8upBackupDirectiveSchema` | `directives/k8up_backup.cue` | #K8upBackupDirectiveSchema:   - schedule / checkSchedule / pruneSchedule / retention — consumed by the     K8up Schedule transformer |

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | #Provider registers the experimental Kubernetes transformers that consume opm_experiments directives and traits |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#K8upPreBackupHookTransformer` | `providers/kubernetes/transformers/k8up_pre_backup_pod.cue` | #K8upPreBackupHookTransformer builds a K8up PreBackupPod CR from a matched #PreBackupHookTrait on a component |
| `#K8upScheduleTransformer` | `providers/kubernetes/transformers/k8up_schedule.cue` | #K8upScheduleTransformer builds a K8up Schedule CR from a matched #K8upBackupDirective |
| `#ResolveSecretRef` | `providers/kubernetes/transformers/k8up_schedule.cue` | #ResolveSecretRef resolves a schemas |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |

---

## Traits

| Definition | File | Description |
|---|---|---|
| `#PreBackupHook` | `traits/pre_backup_hook.cue` | #PreBackupHook: convenience wrapper that attaches the trait to a component |
| `#PreBackupHookDefaults` | `traits/pre_backup_hook.cue` | #PreBackupHookDefaults: no meaningful defaults — the module author must specify image + command |
| `#PreBackupHookSchema` | `traits/pre_backup_hook.cue` | #PreBackupHookSchema describes the hook container |
| `#PreBackupHookTrait` | `traits/pre_backup_hook.cue` | #PreBackupHookTrait: declares a quiescing command that K8up should run as a PreBackupPod before backing up the component |

---

