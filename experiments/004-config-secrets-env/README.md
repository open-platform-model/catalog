# Experiment 004: Config, Secrets & Env Wiring

Implements RFC-0002 (Sensitive Data Model), RFC-0003 (Immutable Config), and RFC-0005 (Env/Config Wiring) as a self-contained experiment against the `v1alpha1` catalog copy.

## What it showcases

### Secret types with variant dispatch

A `#Secret` disjunction (`#SecretLiteral | #SecretK8sRef | #SecretEsoRef`) lets module authors declare sensitive fields once. The transformer dispatches per variant:

- **`#SecretLiteral`** — user provides the value inline. Transformer emits a K8s `Secret` with `stringData`.
- **`#SecretK8sRef`** — points to a pre-existing K8s Secret. Transformer emits nothing (the resource already exists). Env vars wire via `secretKeyRef` using `secretName`/`remoteKey`.
- **`#SecretEsoRef`** — points to an external store via ESO. Transformer emits an `ExternalSecret` CR.

Mixed variants within a single `#SecretSchema` are supported — each data entry is dispatched independently.

### Immutable config with content-hash naming (RFC-0003)

`#ConfigMapSchema` and `#SecretSchema` have an `immutable` field (default `false`). When `true`:

- The K8s resource name gets a 10-character content hash suffix (e.g., `app-config-0c266dbfad`).
- The K8s resource gets `immutable: true`.
- Name computation is deterministic — the same data always produces the same hash.

The hash is computed by `#ContentHash` (sorted key=value pairs, SHA256, first 5 bytes hex-encoded). `#SecretContentHash` normalizes `#Secret` variants to strings before delegating.

### Full env var dispatch (RFC-0005)

`#EnvVarSchema` supports four source types, each mapped to the correct K8s env entry:

| OPM field | K8s output |
|-----------|------------|
| `value: "info"` | `{name, value}` |
| `from: <#Secret>` | `{name, valueFrom: {secretKeyRef: ...}}` |
| `fieldRef: {fieldPath: "metadata.name"}` | `{name, valueFrom: {fieldRef: ...}}` |
| `resourceFieldRef: {resource: "limits.cpu"}` | `{name, valueFrom: {resourceFieldRef: ...}}` |

`envFrom` supports bulk injection from ConfigMaps and Secrets with optional prefix.

### Volume source references via CUE unification

Volumes reference `spec.configMaps` or `spec.secrets` entries directly (CUE references, not copies). Because it's the same data:

- `#ToK8sVolumes` computes the K8s resource name using the same hash helpers as the ConfigMap/Secret transformers.
- Volume names and transformer output names always agree — no coordination needed.
- `#VolumeMountSchema` embeds `#VolumeSchema` (carries full source data), but `#ToK8sContainer` strips it to `{name, mountPath, subPath?, readOnly?}` for K8s.

## How to test

From `experiments/004-config-secrets-env/`:

```bash
export CUE_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'

# All outputs
cue export ./test/

# Individual transformer outputs
cue export -e deployment.output ./test/    # K8s Deployment
cue export -e secrets.output ./test/       # K8s Secret + ExternalSecret
cue export -e configmaps.output ./test/    # K8s ConfigMap
```

The test harness (`test/test.cue`) bypasses the Module/Release pipeline. It builds a concrete component inline with all features wired up, then feeds it directly to three transformers. No CLI required.

## CUE pitfall: open pattern forwarding in definitions

Discovered during this experiment. When a CUE definition field uses an open pattern like `[string]: string`, forwarding it to another definition via `{data: data}` loses concrete values — only the constraint propagates. The comprehension `for k, _ in data` then iterates zero fields.

```text
BROKEN:    _hash: (#ContentHash & {data: data}).out     // data is empty inside
WORKS:     let _d = data
           _hash: (#ContentHash & {data: _d}).out       // _d captures concrete values
```

This applies to all field types (`#`-prefixed, regular, `_`-hidden). The `let` binding is the fix — it evaluates and captures the concrete value at that point in unification.

## Files changed

### Schemas (`schemas/`)

| File | Changes |
|------|---------|
| `config.cue` | `#Secret` types, `#SecretSchema`/`#ConfigMapSchema` (non-optional `immutable`/`type`), hash helpers with `let` fix, discovery pipeline |
| `workload.cue` | `#EnvVarSchema` (4 source types), `#FieldRefSchema`, `#ResourceFieldRefSchema`, `#EnvFromSource`, `envFrom` on `#ContainerSchema` |
| `storage.cue` | `#VolumeSchema` configMap/secret sources, non-optional `readOnly` on `#VolumeMountSchema` |
| `common.cue` | `#NameType` (mirrors `core.#NameType` for use in schemas) |

### Resources (`resources/config/`)

| File | Changes |
|------|---------|
| `configmap.cue` | Auto-name from map key |
| `secret.cue` | Auto-name from map key |

### Transformers (`providers/kubernetes/transformers/`)

| File | Changes |
|------|---------|
| `container_helpers.cue` | Env dispatch (4 types), envFrom, volumeMount stripping, `#ToK8sVolumes` (all volume types) |
| `secret_transformer.cue` | Variant dispatch per `#Secret` entry, ExternalSecret CR emission, immutable naming |
| `configmap_transformer.cue` | Immutable naming + flag |
| `deployment_transformer.cue` | Uses `#ToK8sVolumes` |
| `statefulset_transformer.cue` | Uses `#ToK8sVolumes` |
| `daemonset_transformer.cue` | Uses `#ToK8sVolumes` |
| `job_transformer.cue` | Uses `#ToK8sVolumes` |
| `cronjob_transformer.cue` | Uses `#ToK8sVolumes` |
