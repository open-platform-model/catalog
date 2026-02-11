## Context

The `opmodel.dev/providers@v0` module contains 12 Kubernetes transformers that convert OPM components into k8s manifests. Each transformer's `output` is typed as `{...}` (open struct) inherited from `core.#Transformer.#transform.output`. The `opmodel.dev/schemas/kubernetes@v0` module already re-exports upstream k8s CUE schemas from `cue.dev/x/k8s.io@v0` (v0.6.0) but is not wired into the providers module.

Transformers fall into two categories:

- **Single-resource** (9): Deployment, StatefulSet, DaemonSet, Job, CronJob, Service, Ingress, HPA, ServiceAccount
- **Multi-resource** (3): ConfigMap, Secret, PVC — emit a map of resources keyed by name

## Goals / Non-Goals

**Goals:**

- Validate every transformer's output against the corresponding upstream k8s CUE schema at CUE evaluation time
- Fix the `volumes` struct-vs-list bug in all 5 workload transformers
- Handle the HPA conditional output pattern without injecting phantom fields
- Establish a pattern that future transformers must follow

**Non-Goals:**

- Changing `core.#Transformer.#transform.output: {...}` — it stays provider-agnostic
- Modifying the `schemas_kubernetes` module itself
- Adding new k8s API group re-exports
- Changing transformer behavior or output values (beyond the volumes fix)

## Decisions

### Decision 1: Direct unification on output

Unify the k8s schema type directly on the `output` field rather than using a separate hidden validation field.

```cue
// Yes — type constraint is immediately visible
output: k8sappsv1.#Deployment & {
    apiVersion: "apps/v1"
    ...
}

// No — hides the constraint in a separate field
output: { ... }
_validated: k8sappsv1.#Deployment & output
```

**Rationale**: Both are semantically equivalent in CUE (unification is commutative). Direct unification makes the contract explicit at the point of definition. Anyone reading the transformer immediately sees what k8s type it must produce.

### Decision 2: Per-value unification for multi-resource transformers

For ConfigMap, Secret, and PVC transformers that output a map of resources, apply the type constraint to each value inside the comprehension:

```cue
output: {
    for name, item in _items {
        "\(name)": k8scorev1.#ConfigMap & {
            apiVersion: "v1"
            kind:       "ConfigMap"
            ...
        }
    }
}
```

**Rationale**: The output map structure `{ [string]: resource }` must remain to support the `transformer.opmodel.dev/list-output` annotation pattern. Wrapping each value validates every emitted resource individually.

### Decision 3: Conditional guard for HPA

Place the type constraint inside the conditional, not outside it:

```cue
output: {
    if #component.spec.scaling.auto != _|_ {
        k8sasv2.#HorizontalPodAutoscaler & {
            apiVersion: "autoscaling/v2"
            kind:       "HorizontalPodAutoscaler"
            ...
        }
    }
}
```

**Alternative considered**: `output: *null | (k8sasv2.#HorizontalPodAutoscaler & { ... })`. Rejected because it changes the output type to a disjunction, which would affect downstream consumers expecting a struct.

**Rationale**: When `scaling.auto` is absent, output stays `{}`. Placing the type outside would cause CUE to inject `apiVersion` and `kind` into the empty struct (unification of `{}` with `#HPA` yields a partial HPA), producing a semantically broken resource.

### Decision 4: Fix volumes as list

Convert volumes from struct comprehension to list comprehension in all 5 workload transformers:

```cue
// Before (struct — invalid k8s)
volumes: {
    for vName, vol in #component.spec.volumes ... {
        (vName): { name: ..., persistentVolumeClaim: ... }
    }
}

// After (list — valid k8s)
volumes: [
    for vName, vol in #component.spec.volumes ... {
        name: vol.name | *vName
        persistentVolumeClaim: claimName: vol.name | *vName
    },
]
```

**Rationale**: Kubernetes `PodSpec.volumes` is `[...#Volume]`. The upstream schema enforces this. Without this fix, unification will fail.

### Decision 5: Import path convention

Use aliased imports with `k8s` prefix for clarity:

```cue
import (
    k8sappsv1 "opmodel.dev/schemas/kubernetes/apps/v1@v0"
    k8scorev1 "opmodel.dev/schemas/kubernetes/core/v1@v0"
    k8sbatchv1 "opmodel.dev/schemas/kubernetes/batch/v1@v0"
    k8snetv1 "opmodel.dev/schemas/kubernetes/networking/v1@v0"
    k8sasv2 "opmodel.dev/schemas/kubernetes/autoscaling/v2@v0"
)
```

Each transformer imports only the package it needs — no blanket imports.

## Risks / Trade-offs

**[Upstream schema strictness]** → The k8s CUE schemas may reject currently-emitted field values if types don't align exactly (e.g., `int` vs `int32`, string vs `resource.Quantity`). **Mitigation**: OPM scaling uses `int & >=1 & <=1000` which is a subset of k8s `int32 & int`. Run `task vet MODULE=providers` after each transformer change to catch conflicts immediately.

**[Volumes output shape change]** → The `volumes` fix changes evaluated output from struct to list, which may break downstream consumers (CLI, rendering engine) that expect the struct shape. **Mitigation**: Verify CLI's `opm mod apply` still works after the change. The list form is what k8s actually expects, so any consumer handling the struct form was already working around a bug.

**[Future schema updates]** → When `cue.dev/x/k8s.io` updates, breaking changes in the upstream schema could fail validation. **Mitigation**: This is intentional — fail fast in CUE rather than producing broken manifests. The `schemas_kubernetes` module pins the version explicitly.

**[Evaluation performance]** → Adding schema unification increases CUE evaluation work. **Mitigation**: The schemas are already in the dependency graph once imported; unification is CUE's core operation and should have negligible impact.
