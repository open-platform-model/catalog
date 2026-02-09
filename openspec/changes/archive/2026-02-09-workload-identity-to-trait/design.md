## Context

WorkloadIdentity is defined as a `core.#Resource` in `resources/security/workload_identity.cue`. It is the only file in the `resources/security` package. It wraps `schemas.#WorkloadIdentitySchema` (name + automountToken) and produces a component mixin that registers into `#resources`.

On the provider side, `#ServiceAccountTransformer` matches on it as a `requiredResource` to emit a K8s ServiceAccount. All 5 workload transformers list it as an `optionalResource` and conditionally inject `serviceAccountName` into pod specs.

The existing security traits (`SecurityContext`, `Encryption`) in `traits/security/` follow an identical structural pattern but use `core.#Trait` with `appliesTo` and register into `#traits`.

## Goals / Non-Goals

**Goals:**

- Reclassify WorkloadIdentity from Resource to Trait
- Match the exact pattern used by SecurityContext and Encryption
- Update all transformer matching (resource → trait) across the K8s provider
- Maintain identical runtime behavior (same K8s objects emitted)
- Keep `#WorkloadIdentitySchema` untouched in `schemas/security.cue`

**Non-Goals:**

- Adding WorkloadIdentity to blueprint `composedTraits` (separate change)
- Changing the schema fields (name, automountToken)
- Modifying core `#Trait` or `#Resource` definitions
- Adding new WorkloadIdentity features

## Decisions

### 1. Mirror the SecurityContext pattern exactly

The new `#WorkloadIdentityTrait` will follow the same structure as `#SecurityContextTrait`:

```cue
#WorkloadIdentityTrait: close(core.#Trait & {
    metadata: {
        apiVersion:  "opmodel.dev/traits/security@v0"
        name:        "workload-identity"
        description: "A workload identity definition for service identity"
    }
    appliesTo: [workload_resources.#ContainerResource]
    #defaults: #WorkloadIdentityDefaults
    #spec: workloadIdentity: schemas.#WorkloadIdentitySchema
})
```

**Why**: Consistency with existing security traits. No new patterns needed.

**Alternative**: Keep as Resource and add a separate "binding trait." Rejected — adds complexity for no benefit (Principle VII).

### 2. FQN changes from resource to trait namespace

Old FQN: `opmodel.dev/resources/security@v0#WorkloadIdentity`
New FQN: `opmodel.dev/traits/security@v0#WorkloadIdentity`

This affects every transformer that references the FQN string as a map key.

**Why**: FQN is derived from `metadata.apiVersion` + `metadata.name`. Changing from resources to traits namespace is automatic and correct.

### 3. ServiceAccountTransformer uses `requiredTraits` instead of `requiredResources`

```cue
// Before
requiredResources: {
    "opmodel.dev/resources/security@v0#WorkloadIdentity": ...
}

// After
requiredTraits: {
    "opmodel.dev/traits/security@v0#WorkloadIdentity": ...
}
```

The `#Matches` logic in `core/transformer.cue` already supports matching on `requiredTraits` identically to `requiredResources`. No core changes needed.

**Why**: This is the only transformer that uses WorkloadIdentity as a required match. Moving it to traits keeps the matching semantics identical.

### 4. Workload transformers move WorkloadIdentity to `optionalTraits`

All 5 workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) currently have:

```cue
optionalResources: {
    "opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource
}
```

This becomes:

```cue
optionalTraits: {
    ...existing traits...
    "opmodel.dev/traits/security@v0#WorkloadIdentity": security_traits.#WorkloadIdentityTrait
}
```

The `#transform` blocks are unchanged — they already access `#component.spec.workloadIdentity` which is populated the same way regardless of whether the definition is a resource or trait (via `_allFields` in `core/component.cue`).

**Why**: The spec field path (`spec.workloadIdentity`) doesn't change because it's derived from the definition's `#spec`, not from whether it's a resource or trait. This means zero changes to transform logic.

### 5. Delete `resources/security/` package entirely

WorkloadIdentity is the sole file. Remove the directory rather than leaving an empty package.

**Why**: Empty packages are confusing. If future security resources are needed, the directory can be recreated.

### 6. Update transformer imports

All transformers currently import:

```cue
security_resources "opmodel.dev/resources/security@v0"
```

This changes to (or merges with existing):

```cue
security_traits "opmodel.dev/traits/security@v0"
```

The DeploymentTransformer already imports `security_traits` for SecurityContext, so it just adds to the existing import. Other workload transformers that import `security_traits` similarly just extend usage. The ServiceAccountTransformer switches its import entirely.

## Risks / Trade-offs

**[Breaking import paths]** → Downstream consumers using `security_resources.#WorkloadIdentity` will get build errors. Mitigated by v0 pre-stable expectation of breaking changes.

**[Trait producing standalone K8s object]** → This sets a precedent that traits can trigger creation of standalone K8s objects (ServiceAccount). This is actually a provider-layer concern, not a model-layer violation — the trait itself doesn't "know" it produces a standalone object. The transformer decides what to emit. → No mitigation needed; this is the correct architectural interpretation.

**[FQN string references]** → Any hardcoded FQN strings referencing the old resource path will silently fail to match. → Mitigated by `task vet` catching structural validation errors and by the test data exercising the transformer.
