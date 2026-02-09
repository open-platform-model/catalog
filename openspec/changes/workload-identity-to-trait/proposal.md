## Why

WorkloadIdentity is currently a Resource, but it behaves semantically like a Trait — it describes a characteristic of a workload ("this workload runs as identity X"), not an independent deployable entity. A workload identity without a workload is meaningless. Converting it to a Trait aligns it with SecurityContext and Encryption in the same security domain, enables blueprint composition, and makes `appliesTo` constraints explicit. Future K8s-native resource definitions will cover standalone ServiceAccount objects separately.

## What Changes

- **BREAKING**: Remove `#WorkloadIdentityResource` and `#WorkloadIdentity` from `resources/security/workload_identity.cue`
- **BREAKING**: Remove the `resources/security` package entirely (WorkloadIdentity is the sole occupant)
- Add `#WorkloadIdentityTrait` and `#WorkloadIdentity` to `traits/security/workload_identity.cue`
- `#WorkloadIdentityTrait` declares `appliesTo: [ContainerResource]`, consistent with other security traits
- The component mixin `#WorkloadIdentity` registers into `#traits` instead of `#resources`
- `#WorkloadIdentitySchema` in `schemas/security.cue` is unchanged
- `#ServiceAccountTransformer` switches from `requiredResources` to `requiredTraits` for matching
- All 5 workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) move WorkloadIdentity from `optionalResources` to `optionalTraits`
- Transformer test data updates component to use `#traits` instead of `#resources`
- SemVer: **MINOR** (v0 pre-stable, breaking changes expected)

## Capabilities

### New Capabilities

- `workload-identity-trait`: Defines WorkloadIdentity as a Trait with `appliesTo` binding to ContainerResource, component mixin registering into `#traits`, and defaults.

### Modified Capabilities

- `k8s-serviceaccount-transformer`: ServiceAccountTransformer matches on `requiredTraits` instead of `requiredResources`. Workload transformers reference WorkloadIdentity via `optionalTraits` instead of `optionalResources`. Test data uses trait-based component composition.

## Impact

- **Modules affected**: resources, traits, providers (transformers + test data)
- **Breaking for downstream consumers**: Any CUE code using `security_resources.#WorkloadIdentity` or `security_resources.#WorkloadIdentityResource` must switch to `security_traits.#WorkloadIdentity` / `security_traits.#WorkloadIdentityTrait`
- **No schema changes**: `#WorkloadIdentitySchema` and `#WorkloadIdentityDefaults` logic is unchanged
- **Blueprints**: Not changed in this PR, but now unblocked for future composition
- **Existing spec `workload-identity-resource`**: Will be superseded by new `workload-identity-trait` spec; the old spec should be archived or updated
