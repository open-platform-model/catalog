# Transformer: Kubernetes Backup

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Overview

A single custom transformer handles the backup primitive(s) and generates K8up custom resources as output, bridging the generic OPM backup contract to the K8up implementation. The transformer structure is the same regardless of which approach (A, B, or C) is chosen — it reads backup config from the component spec and emits K8up resources.

---

## Transformer Definition

```cue
#BackupTransformer: transformer.#Transformer & {
    metadata: {
        name:        "backup-transformer"
        description: "Converts Backup trait to K8up Schedule and optional PreBackupPod"
    }

    requiredTraits: {
        "opmodel.dev/opm/v1alpha1/traits/data/backup@v1": data_traits.#BackupTrait
    }

    optionalTraits: {
        "opmodel.dev/opm/v1alpha1/traits/data/pre-backup-hook@v1": data_traits.#PreBackupHookTrait
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        _backup: #component.spec.backup
        _name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

        // Always emit: K8up Schedule
        _schedule: { ... }

        // Conditionally emit: K8up PreBackupPod (only when hook trait is present)
        _preBackupPod: { ... }

        output: [_schedule] + _preBackupPod
    }
}
```

> **Note:** In Approach C, the pre-backup hook is a separate trait referenced via `optionalTraits`. In Approaches A and B, the hook is an inline field (`preBackupHook?`) within the backup schema — the transformer checks for its presence conditionally. The generated K8up resources are identical in all cases.

---

## Generated Resources

### K8up Schedule (always generated)

The transformer maps the generic backup schema fields to a K8up Schedule CR:

```yaml
apiVersion: k8up.io/v1
kind: Schedule
metadata:
  name: "{release}-{component}-backup"
  namespace: "{release-namespace}"
  labels: "{release-labels}"
spec:
  backend:
    repoPasswordSecretRef:
      name: "{resolved secret name}"
      key: "{resolved secret key}"
    s3:
      endpoint: "{backup.backend.s3.endpoint}"
      bucket: "{backup.backend.s3.bucket}"
      accessKeyIDSecretRef:
        name: "{resolved secret name}"
        key: "{resolved secret key}"
      secretAccessKeySecretRef:
        name: "{resolved secret name}"
        key: "{resolved secret key}"
  backup:
    schedule: "{backup.schedule}"
  check:
    schedule: "{backup.checkSchedule}"
  prune:
    schedule: "{backup.pruneSchedule}"
    retention:
      keepDaily: {backup.retention.keepDaily}
      keepWeekly: {backup.retention.keepWeekly}
      keepMonthly: {backup.retention.keepMonthly}
```

### K8up PreBackupPod (conditionally generated)

Only generated when the component has a pre-backup hook (separate trait in Approach C, inline field in A/B). Maps the hook schema to a K8up PreBackupPod CR:

```yaml
apiVersion: k8up.io/v1
kind: PreBackupPod
metadata:
  name: "{release}-{component}-pre-backup"
  namespace: "{release-namespace}"
  labels: "{release-labels}"
spec:
  backupCommand: "{preBackupHook.command joined}"
  pod:
    spec:
      containers:
        - name: pre-backup
          image: "{preBackupHook.image}"
          command: {preBackupHook.command}
          volumeMounts:
            # Only if preBackupHook.volumeMount is set
            - name: data
              mountPath: "{preBackupHook.volumeMount.mountPath}"
      volumes:
        # Only if preBackupHook.volumeMount is set
        - name: data
          persistentVolumeClaim:
            claimName: "{preBackupHook.volumeMount.pvcName}"
```

---

## Secret Resolution

The transformer reuses the existing `#ResolveSecretRef` pattern from the K8up catalog's schedule transformer. This handles both:

- OPM `schemas.#Secret` references (with `$opm` discriminator) that are auto-created by the pipeline
- Plain `{name, key}` passthrough for pre-existing secrets

The secret resolution logic dispatches based on the presence of the `$opm` field, consistent with all other OPM transformers.

---

## PVC Annotation

K8up discovers PVCs to back up via the `k8up.io/backup=true` annotation. The transformer must ensure the target PVC (identified by `backup.pvcName` or resolved from `backup.targets`) is annotated. Two approaches:

### Option A: Emit a PVC patch annotation

The transformer emits the annotation instruction, and the pipeline or a downstream reconciler applies it. This requires pipeline support for annotation patching that may not exist today.

### Option B: Rely on existing PVC annotation in the module

The module's workload component already defines the PVC. The backup transformer does not modify it — the module author or a convention ensures the PVC has the `k8up.io/backup=true` annotation.

### Recommendation

Option B for v1. The PVC is defined by the module's workload component, and the backup primitive is a separate concern. Cross-component mutation (trait on component A modifying component B's PVC annotations) introduces complexity. The module author adds the annotation to the PVC definition, or the K8up operator is configured to not require it (via `skipWithoutAnnotation: false` on the K8up operator config).

---

## Provider Registration

The transformer is registered in the OPM Kubernetes provider alongside existing transformers:

```cue
// catalog/opm/v1alpha1/providers/kubernetes/provider.cue
#Provider: provider.#Provider & {
    #transformers: {
        // ... existing transformers ...
        (k8s_transformers.#BackupTransformer.metadata.fqn): k8s_transformers.#BackupTransformer
    }
}
```

---

## K8up Catalog Dependency

The transformer imports K8up CRD types from the existing K8up catalog (`opmodel.dev/k8up/v1alpha1`) for type-safe output generation. This is an implementation dependency of the Kubernetes provider, not of the backup contract.

If the backup provider changes (e.g., to Velero), only this transformer is replaced. The backup schemas and module-level usage remain unchanged.
