## Why

Kubernetes transformer output is structurally unvalidated. The `#Transformer.#transform.output` type is `{...}` (open struct), meaning any field name, wrong type, or structurally invalid resource passes CUE evaluation silently. The `opmodel.dev/schemas/kubernetes@v0` module already re-exports upstream k8s CUE schemas but is completely disconnected from the providers module. We already found one concrete bug: all 5 workload transformers emit `volumes` as a struct instead of the list that Kubernetes requires.

This is a MINOR change — no breaking API changes. It adds compile-time schema validation to existing transformer output without changing the output values (except fixing the volumes bug).

## What Changes

- Add `opmodel.dev/schemas/kubernetes@v0` as a dependency of the `opmodel.dev/providers@v0` module
- Unify each transformer's output with the corresponding upstream k8s type (e.g., `output: k8sappsv1.#Deployment & { ... }`)
- For multi-resource transformers (ConfigMap, Secret, PVC), unify each value in the output map with the corresponding type
- **Fix `volumes` struct-to-list bug** in all 5 workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) — currently emits a struct but k8s `PodSpec.volumes` requires `[...#Volume]`
- Handle HPA transformer's conditional output by placing the type constraint inside the conditional guard

## Capabilities

### New Capabilities

- `k8s-transformer-schema-validation`: Transformer output is validated against upstream Kubernetes CUE schemas at evaluation time, catching field typos, wrong types, and structural errors before deployment.

### Modified Capabilities

- `k8s-schema-reexport`: The existing schema re-export module gains its first consumer (the providers module). No requirement changes — just documenting the new dependency relationship.

## Impact

- **Affected module**: `opmodel.dev/providers@v0` — new dependency on `opmodel.dev/schemas/kubernetes@v0`, all 12 transformer files modified
- **Affected files**: All files in `v0/providers/kubernetes/transformers/`
- **Dependency change**: `v0/providers/cue.mod/module.cue` gains a new dep entry
- **Bug fix**: `volumes` field changes from struct to list in 5 workload transformers — this changes the evaluated output shape (struct → list), which may affect downstream consumers that read transformer output
- **Validation strictness**: Future transformer modifications that produce invalid k8s fields will fail at `cue vet` time rather than silently passing
