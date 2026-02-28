## 1. Schemas Module — CRD Schema

- [x] 1.1 Add `#CRDVersionSchema` and `#CRDSchema` definitions to `v1alpha1/schemas/extension.cue`
- [x] 1.2 Run `task fmt` and `task vet` to validate

## 2. Schemas/Kubernetes Module — Apiextensions Wrapper

- [x] 2.1 Create `v1alpha1/schemas/kubernetes/apiextensions/v1/types.cue` re-exporting `#CustomResourceDefinition` from `cue.dev/x/k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1`
- [x] 2.2 Run `task fmt` and `task vet` to validate

## 3. Resources Module — CRDs Resource

- [x] 3.1 Create `v1alpha1/resources/extension/crd.cue` with `#CRDsResource`, `#CRDs`, and `#CRDsDefaults`
- [x] 3.2 Create `v1alpha1/resources/extension/crd_tests.cue` with resource definition test, single CRD component test, and multi-CRD component test
- [x] 3.3 Run `task fmt` and `task vet` to validate

## 4. Providers Module — CRD Transformer

- [x] 4.1 Create `v1alpha1/providers/kubernetes/transformers/crd_transformer.cue` with `#CRDTransformer`
- [x] 4.2 Register `#CRDTransformer` in `v1alpha1/providers/kubernetes/provider.cue`
- [x] 4.3 Run `task fmt` and `task vet` to validate

## 5. Final Validation

- [x] 5.1 Run `task fmt` (all modules) — ensure no formatting diffs
- [x] 5.2 Run `task vet` (all modules) — ensure all definitions validate
- [x] 5.3 Run `task eval` — verify evaluated output looks correct
