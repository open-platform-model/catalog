## 1. Create WorkloadIdentity trait definition

- [x] 1.1 Create `v0/traits/security/workload_identity.cue` with `#WorkloadIdentityTrait`, `#WorkloadIdentity` component mixin, and `#WorkloadIdentityDefaults` — mirror the `#SecurityContextTrait` pattern exactly
- [x] 1.2 Verify `task vet MODULE=traits` passes with the new trait

## 2. Update ServiceAccountTransformer

- [x] 2.1 In `v0/providers/kubernetes/transformers/serviceaccount_transformer.cue`: replace `security_resources` import with `security_traits`, move WorkloadIdentity from `requiredResources` to `requiredTraits` with new FQN `opmodel.dev/traits/security@v0#WorkloadIdentity`, and empty `requiredResources`
- [x] 2.2 Update test component `_testServiceAccountComponent` in `v0/providers/kubernetes/transformers/test_data.cue` to use `#traits` with `#WorkloadIdentityTrait` instead of `#resources` with `#WorkloadIdentityResource`, and update the test data imports accordingly

## 3. Update workload transformers

- [x] 3.1 In `v0/providers/kubernetes/transformers/deployment_transformer.cue`: remove `security_resources` import (keep `security_traits`), move WorkloadIdentity from `optionalResources` to `optionalTraits` with new FQN, empty `optionalResources`
- [x] 3.2 In `v0/providers/kubernetes/transformers/statefulset_transformer.cue`: replace `security_resources` import with `security_traits`, move WorkloadIdentity from `optionalResources` to `optionalTraits` with new FQN, empty `optionalResources`
- [x] 3.3 In `v0/providers/kubernetes/transformers/daemonset_transformer.cue`: replace `security_resources` import with `security_traits`, move WorkloadIdentity from `optionalResources` to `optionalTraits` with new FQN, empty `optionalResources`
- [x] 3.4 In `v0/providers/kubernetes/transformers/job_transformer.cue`: replace `security_resources` import with `security_traits`, move WorkloadIdentity from `optionalResources` to `optionalTraits` with new FQN, empty `optionalResources`
- [x] 3.5 In `v0/providers/kubernetes/transformers/cronjob_transformer.cue`: replace `security_resources` import with `security_traits`, move WorkloadIdentity from `optionalResources` to `optionalTraits` with new FQN, empty `optionalResources`

## 4. Remove old resource definition

- [x] 4.1 Delete `v0/resources/security/workload_identity.cue` and the `v0/resources/security/` directory entirely
- [x] 4.2 Run `task tidy MODULE=resources` and `task tidy MODULE=providers` to clean up module dependencies

## 5. Validation

- [x] 5.1 Run `task fmt` to ensure all CUE files are formatted
- [x] 5.2 Run `task vet` to ensure all modules validate
- [x] 5.3 Run `task eval MODULE=providers OUTPUT=eval-output.cue` and verify the ServiceAccount transformer output is unchanged (same K8s ServiceAccount and serviceAccountName injection)
