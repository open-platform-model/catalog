# Transformer Integration — K8up Backup & PreBackup Hook

## Overview

Two transformers consume the experimental schemas in `opm_experiments/v1alpha1`:

| Transformer | Consumes | Produces |
|---|---|---|
| K8up Schedule transformer | `#K8upBackupDirective` (on a policy targeting the component) | K8up `Schedule` CR |
| K8up PreBackupPod transformer | `#PreBackupHookTrait` (on the component) | K8up `PreBackupPod` CR |

The `restore` block of `#K8upBackupDirective` is **not** consumed by any transformer. It is data read at runtime by the OPM CLI (see 05-cli-integration.md).

---

## Matching

The transformer matching rule becomes four-dimensional. A transformer matches a component when all of these hold:

1. All `requiredLabels` are present on the component with matching values.
2. All `requiredResources` FQNs appear in `component.#resources`.
3. All `requiredTraits` FQNs appear in `component.#traits`.
4. All `requiredDirectives` FQNs appear in `#Policy.#directives` for a policy whose `appliesTo` targets this component.

`optionalDirectives` extends the data available to the transformer without affecting the match decision.

### Enrichment

When a transformer matches via a directive, the pipeline enriches `#component.spec` with the directive's spec fields before invoking `#transform`. The transformer accesses them the same way it accesses trait specs. For the K8up backup directive, `#component.spec.k8upBackup` is populated with the unified schema.

The same enrichment rule applies to traits. The PreBackupPod transformer reads `#component.spec.preBackupHook`.

---

## K8up Schedule Transformer

Matches any component covered by a policy carrying a `#K8upBackupDirective`. One Schedule CR per matched component.

```cue
#K8upScheduleTransformer: transformer.#Transformer & {
    metadata: {
        modulePath:  "opmodel.dev/opm_experiments/v1alpha1/providers/kubernetes/transformers"
        version:     "v0"
        name:        "k8up-schedule-transformer"
        description: "Generates a K8up Schedule CR from #K8upBackupDirective"
    }

    requiredDirectives: {
        (exp_directives.#K8upBackupDirective.metadata.fqn): exp_directives.#K8upBackupDirective
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        _d: #component.spec.k8upBackup
        _name: "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)"

        output: _schedule
    }
}
```

### Schedule output

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
      name: "{resolved from repository.password}"
      key:  "{resolved key}"
    s3:
      endpoint: "{repository.s3.endpoint}"
      bucket:   "{repository.s3.bucket}"
      accessKeyIDSecretRef:
        name: "{resolved from repository.s3.accessKeyID}"
        key:  "{resolved key}"
      secretAccessKeySecretRef:
        name: "{resolved from repository.s3.secretAccessKey}"
        key:  "{resolved key}"
  backup:
    schedule: "{k8upBackup.schedule}"
  check:
    schedule: "{k8upBackup.checkSchedule}"
  prune:
    schedule: "{k8upBackup.pruneSchedule}"
    retention:
      keepDaily:   "{retention.keepDaily}"
      keepWeekly:  "{retention.keepWeekly}"
      keepMonthly: "{retention.keepMonthly}"
```

No `podSelector` or per-PVC targeting on the Schedule itself — K8up selects PVCs at its own layer (see the PVC annotation section below).

---

## K8up PreBackupPod Transformer

Matches any component that carries `#PreBackupHookTrait`. One PreBackupPod CR per matched component.

```cue
#K8upPreBackupHookTransformer: transformer.#Transformer & {
    metadata: {
        modulePath:  "opmodel.dev/opm_experiments/v1alpha1/providers/kubernetes/transformers"
        version:     "v0"
        name:        "k8up-pre-backup-hook-transformer"
        description: "Generates a K8up PreBackupPod CR from #PreBackupHookTrait"
    }

    requiredTraits: {
        (exp_traits.#PreBackupHookTrait.metadata.fqn): exp_traits.#PreBackupHookTrait
    }

    #transform: {
        #component: _
        #context:   transformer.#TransformerContext

        _hook: #component.spec.preBackupHook
        _name: "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)"

        output: _preBackupPod
    }
}
```

### PreBackupPod output

```yaml
apiVersion: k8up.io/v1
kind: PreBackupPod
metadata:
  name: "{release}-{component}-pre-backup"
  namespace: "{release-namespace}"
  labels: "{context labels}"
spec:
  backupCommand: "{preBackupHook.command joined}"
  pod:
    spec:
      containers:
        - name: pre-backup
          image: "{preBackupHook.image}"
          command: "{preBackupHook.command}"
          # volumeMounts/volumes only emitted when preBackupHook.volumeMount is set
          volumeMounts:
            - name: data
              mountPath: "{preBackupHook.volumeMount.mountPath}"
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: "{resolved PVC name from volume reference}"
```

### Volume resolution

When `preBackupHook.volumeMount.volume` is set, the transformer looks the volume name up on the component's `spec.volumes[volumeName]` and resolves it to a PVC name using the release's naming convention. If the named volume does not exist on the component, CUE evaluation fails — the reference is validated at definition time.

---

## PVC Annotation — open

K8up only backs up a PVC if one of these holds:

1. The PVC carries `k8up.io/backup=true`.
2. The K8up operator runs with `skipWithoutAnnotation: false`.

The transformer model as it stands cannot annotate PVCs from a directive that targets another component (cross-component mutation is not supported). See 07-open-questions.md Q1 for the options on the table and the dogfooding default.

---

## Secret Resolution

Both transformers use the existing `#ResolveSecretRef` helper from the K8up catalog. Dispatch is by the `$opm` discriminator on `schemas.#Secret`:

- OPM-managed secret references: pipeline auto-creates the Secret, helper returns `{name, key}`.
- Plain `{name, key}` passthrough: used directly.

No new secret-resolution machinery is introduced by this enhancement.

---

## Provider Registration

Both transformers register under the experimental Kubernetes provider. A consumer wiring looks like:

```cue
#Provider: provider.#Provider & {
    #transformers: {
        // ... existing transformers ...
        (exp_transformers.#K8upScheduleTransformer.metadata.fqn):         exp_transformers.#K8upScheduleTransformer
        (exp_transformers.#K8upPreBackupHookTransformer.metadata.fqn):    exp_transformers.#K8upPreBackupHookTransformer
    }
}
```

Once the experimental directive + trait graduate to `opm/v1alpha1`, the registration moves with them.

---

## Restore Block

The `restore` sub-block of `#K8upBackupDirective` is runtime data for the CLI. No transformer consumes it. No Kubernetes resource is generated from it. See 05-cli-integration.md.
