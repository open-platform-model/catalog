# Transformer Integration — K8up Backup Directive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Overview

The `#K8upBackupDirective` is consumed by K8up-specific transformers via the `requiredDirectives` matching field. The `#RestoreDirective` is not consumed by transformers — it is read directly by the CLI.

---

## `#Transformer` Changes

Two new fields on `#Transformer`:

```cue
#Transformer: {
    // ... existing fields ...

    // Directives required by this transformer.
    // The pipeline matches these against directives in Policies that target the component.
    requiredDirectives: [string]: _

    // Directives optionally used by this transformer.
    optionalDirectives: [string]: _

    #transform: {
        #component: _
        #context:   #TransformerContext
        output:     {...}
    }
}
```

### Matching Logic

A transformer matches a component when ALL of:

1. ALL `requiredLabels` are present on the component with matching values (unchanged)
2. ALL `requiredResources` FQNs exist in `component.#resources` (unchanged)
3. ALL `requiredTraits` FQNs exist in `component.#traits` (unchanged)
4. **NEW**: ALL `requiredDirectives` FQNs exist in any `#Policy.#directives` where `appliesTo` targets this component

### Directive Data Access

**Recommendation:** The pipeline enriches the component with directive data before passing to the transformer. The transformer accesses `#component.spec.k8upBackup` directly, mirroring how trait specs are accessed (`#component.spec.scaling`, `#component.spec.expose`).

---

## K8up Schedule Transformer

```cue
#K8upScheduleTransformer: transformer.#Transformer & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
        version:     "v0"
        name:        "k8up-schedule-transformer"
        description: "Converts K8upBackupDirective to K8up Schedule CR"
    }

    requiredDirectives: {
        (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        _backup: #component.spec.k8upBackup
        _componentName: #context.#componentMetadata.name
        _name: "\(#context.#moduleReleaseMetadata.name)-\(_componentName)"

        output: _schedule
    }
}
```

### K8up Schedule Output

```yaml
apiVersion: k8up.io/v1
kind: Schedule
metadata:
  name: "{release}-{component}-backup"
  namespace: "{release-namespace}"
  labels: "{context labels}"
spec:
  backend:
    repoPasswordSecretRef:
      name: "{resolved from k8upBackup.backend.repoPassword}"
      key: "{resolved key}"
    s3:
      endpoint: "{k8upBackup.backend.s3.endpoint}"
      bucket: "{k8upBackup.backend.s3.bucket}"
      accessKeyIDSecretRef:
        name: "{resolved from k8upBackup.backend.s3.accessKeyID}"
        key: "{resolved key}"
      secretAccessKeySecretRef:
        name: "{resolved from k8upBackup.backend.s3.secretAccessKey}"
        key: "{resolved key}"
  backup:
    schedule: "{k8upBackup.schedule}"
  check:
    schedule: "{k8upBackup.checkSchedule}"
  prune:
    schedule: "{k8upBackup.pruneSchedule}"
    retention:
      keepDaily: "{k8upBackup.retention.keepDaily}"
      keepWeekly: "{k8upBackup.retention.keepWeekly}"
      keepMonthly: "{k8upBackup.retention.keepMonthly}"
```

---

## K8up PreBackupPod Transformer

Generated only when `targets[component].preBackupHook` is present. Separate transformer — one output per transformer.

```cue
#K8upPreBackupHookTransformer: transformer.#Transformer & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
        version:     "v0"
        name:        "k8up-pre-backup-hook-transformer"
        description: "Converts K8upBackupDirective preBackupHook to K8up PreBackupPod CR"
    }

    requiredDirectives: {
        (k8up_directives.#K8upBackupDirective.metadata.fqn): k8up_directives.#K8upBackupDirective
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        _backup: #component.spec.k8upBackup
        _componentName: #context.#componentMetadata.name
        _targets: _backup.targets[_componentName]
        _name: "\(#context.#moduleReleaseMetadata.name)-\(_componentName)"

        output: _preBackupPod
    }
}
```

### K8up PreBackupPod Output

```yaml
apiVersion: k8up.io/v1
kind: PreBackupPod
metadata:
  name: "{release}-{component}-pre-backup"
  namespace: "{release-namespace}"
  labels: "{context labels}"
spec:
  backupCommand: "{targets[component].preBackupHook.command joined}"
  pod:
    spec:
      containers:
        - name: pre-backup
          image: "{targets[component].preBackupHook.image}"
          command: "{targets[component].preBackupHook.command}"
          volumeMounts:
            # Only if volumeMount is set
            - name: data
              mountPath: "{targets[component].preBackupHook.volumeMount.mountPath}"
      volumes:
        # Only if volumeMount is set
        - name: data
          persistentVolumeClaim:
            claimName: "{resolved PVC name from volume reference}"
```

### Volume Name Resolution

The transformer resolves volume names from `targets[component].volumes` and `preBackupHook.volumeMount.volume` to PVC names by looking up the component's `spec.volumes[volumeName]`. For a volume with `persistentClaim`, the PVC name is derived from the claim spec and the module release naming convention.

---

## Resource Type Handling

| Resource type | Backup method | Transformer output |
|--------------|--------------|-------------------|
| `volumes` | File-level backup via Restic | K8up Schedule targeting the PVC |
| `configMaps` | API object export | Implementation TBD (v2) |
| `secrets` | API object export | Implementation TBD (v2) |

For v1, the transformer focuses on volume backup via K8up. ConfigMap and Secret backup support is defined in the schema for forward compatibility.

---

## Secret Resolution

Reuses the existing `#ResolveSecretRef` pattern from the K8up catalog's schedule transformer. Dispatches based on the `$opm` discriminator in `schemas.#Secret`:

- OPM secret references (with `$opm`): auto-created by the pipeline, resolved to `{name, key}`
- Plain `{name, key}` passthrough: used directly as secret references

---

## Provider Registration

Both transformers are registered in the Kubernetes provider:

```cue
#Provider: provider.#Provider & {
    #transformers: {
        // ... existing transformers ...
        (k8s_transformers.#K8upScheduleTransformer.metadata.fqn):         k8s_transformers.#K8upScheduleTransformer
        (k8s_transformers.#K8upPreBackupHookTransformer.metadata.fqn):    k8s_transformers.#K8upPreBackupHookTransformer
    }
}
```

---

## PVC Annotation

Same recommendation as enhancement 004: module author adds `k8up.io/backup=true` to the PVC definition, or the K8up operator is configured with `skipWithoutAnnotation: false`. Cross-component mutation is not supported by the transformer model.

---

## `#RestoreDirective` and Transformers

The `#RestoreDirective` is **not consumed by transformers**. It generates no Kubernetes resources. It is a data contract read by the OPM CLI at runtime. No transformer registration needed.
