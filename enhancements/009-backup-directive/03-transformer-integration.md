# Transformer Integration — `#Directive` Primitive: Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Overview

Directives are consumed by Transformers via new matching fields: `requiredDirectives` and `optionalDirectives`. When a Transformer declares a required directive, the rendering pipeline checks whether any `#Policy` targeting the current component contains that directive FQN. This extends the existing matching logic (labels, resources, traits) with a fourth dimension.

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

The rendering pipeline resolves directive matching by:

1. Iterating all `#policies` in the module
2. For each policy, checking if `appliesTo.components` or `appliesTo.matchLabels` matches the current component
3. If matched, collecting the policy's `#directives` FQNs into the component's directive set
4. Checking the transformer's `requiredDirectives` against this collected set

### Directive Data Access

The transformer's `#transform` function receives directive data via the component's policy spec. Since `#Policy._allFields` merges directive specs into `Policy.spec`, and policies are associated with components via `appliesTo`, the directive values are accessible through the resolved component context.

The exact mechanism depends on how the rendering pipeline passes policy data to transformers. Two options:

**Option A: Via `#TransformerContext`** — Add a `#directives` field to `#TransformerContext` containing matched directive specs:

```cue
#TransformerContext: {
    // ... existing fields ...
    #directives?: [string]: _ // Directive specs from matched policies
}
```

**Option B: Via `#component` enrichment** — The pipeline enriches the component with directive data before passing to the transformer. The transformer accesses `#component.spec.backup` directly.

**Recommendation:** Option B — it mirrors how trait specs are accessed (`#component.spec.scaling`, `#component.spec.expose`). Directives contribute to the policy `spec`, which is associated with the component. The transformer accesses directive fields through the same `spec` path.

---

## Backup Directive Transformer

```cue
#BackupDirectiveTransformer: transformer.#Transformer & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
        version:     "v0"
        name:        "backup-directive-transformer"
        description: "Converts BackupDirective to K8up Schedule and optional PreBackupPod"
    }

    requiredDirectives: {
        (data_directives.#BackupDirective.metadata.fqn): data_directives.#BackupDirective
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        _backup: #component.spec.backup
        _name:   "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)"

        output: _schedule
    }
}
```

Note: The current transformer model produces a single output resource. The backup transformer generates a K8up Schedule. The PreBackupPod may require a second transformer or an extension to allow multiple outputs. This is consistent with the existing model where one component matches multiple transformers, each producing one resource.

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
      name: "{resolved from backup.backend.repoPassword}"
      key: "{resolved key}"
    s3:
      endpoint: "{backup.backend.s3.endpoint}"
      bucket: "{backup.backend.s3.bucket}"
      accessKeyIDSecretRef:
        name: "{resolved from backup.backend.s3.accessKeyID}"
        key: "{resolved key}"
      secretAccessKeySecretRef:
        name: "{resolved from backup.backend.s3.secretAccessKey}"
        key: "{resolved key}"
  backup:
    schedule: "{backup.schedule}"
  check:
    schedule: "{backup.checkSchedule}"
  prune:
    schedule: "{backup.pruneSchedule}"
    retention:
      keepDaily: "{backup.retention.keepDaily}"
      keepWeekly: "{backup.retention.keepWeekly}"
      keepMonthly: "{backup.retention.keepMonthly}"
```

### K8up PreBackupPod Output (conditional)

Generated only when `backup.preBackupHook` is present. Requires a second transformer:

```cue
#PreBackupHookTransformer: transformer.#Transformer & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
        version:     "v0"
        name:        "pre-backup-hook-transformer"
        description: "Converts BackupDirective preBackupHook to K8up PreBackupPod"
    }

    requiredDirectives: {
        (data_directives.#BackupDirective.metadata.fqn): data_directives.#BackupDirective
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        // Only produces output when preBackupHook is set
        // The pipeline handles conditional output
        _backup: #component.spec.backup
        _name:   "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)"

        output: _preBackupPod
    }
}
```

```yaml
apiVersion: k8up.io/v1
kind: PreBackupPod
metadata:
  name: "{release}-{component}-pre-backup"
  namespace: "{release-namespace}"
  labels: "{context labels}"
spec:
  backupCommand: "{backup.preBackupHook.command joined}"
  pod:
    spec:
      containers:
        - name: pre-backup
          image: "{backup.preBackupHook.image}"
          command: "{backup.preBackupHook.command}"
          volumeMounts:
            # Only if volumeMount is set
            - name: data
              mountPath: "{backup.preBackupHook.volumeMount.mountPath}"
      volumes:
        # Only if volumeMount is set
        - name: data
          persistentVolumeClaim:
            claimName: "{backup.preBackupHook.volumeMount.pvcName}"
```

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
        (k8s_transformers.#BackupDirectiveTransformer.metadata.fqn): k8s_transformers.#BackupDirectiveTransformer
        (k8s_transformers.#PreBackupHookTransformer.metadata.fqn):   k8s_transformers.#PreBackupHookTransformer
    }
}
```

---

## PVC Annotation

Same recommendation as enhancement 004: module author adds `k8up.io/backup=true` to the PVC definition, or the K8up operator is configured with `skipWithoutAnnotation: false`. Cross-component mutation (transformer modifying another component's PVC annotations) is not supported by the current transformer model.
