## 1. Schema Changes (schemas module)

- [x] 1.1 Add `#ServiceAccountSchema` to `v1alpha1/schemas/security.cue` with `name!: string` and `automountToken?: bool`
- [x] 1.2 Add `#PolicyRuleSchema` to `v1alpha1/schemas/security.cue` with `apiGroups!: [...string]`, `resources!: [...string]`, `verbs!: [...string]`
- [x] 1.3 Add `#RoleSubjectSchema` to `v1alpha1/schemas/security.cue` as `{#WorkloadIdentitySchema | #ServiceAccountSchema}` (embedded disjunction, no wrapper field)
- [x] 1.4 Add `#RoleSchema` to `v1alpha1/schemas/security.cue` with `name!: string`, `scope: *"namespace" | "cluster"`, `rules!: [...#PolicyRuleSchema] & [_, ...]`, `subjects!: [...#RoleSubjectSchema] & [_, ...]`
- [x] 1.5 Run `task fmt MODULE=schemas` and `task vet MODULE=schemas` to validate schema changes

## 2. ServiceAccount Resource (resources module)

- [x] 2.1 Create `v1alpha1/resources/security/` directory
- [x] 2.2 Create `v1alpha1/resources/security/service_account.cue` with `#ServiceAccountResource`, `#ServiceAccount` component mixin, and `#ServiceAccountDefaults` (automountToken defaults to false)
- [x] 2.3 Run `task vet MODULE=resources` to validate ServiceAccount resource

## 3. Role Resource (resources module)

- [x] 3.1 Create `v1alpha1/resources/security/role.cue` with `#RoleResource`, `#Role` component mixin (with `"transformer.opmodel.dev/list-output": true` annotation), and `#RoleDefaults`
- [x] 3.2 Run `task vet MODULE=resources` to validate Role resource

## 4. ServiceAccount Resource Transformer (providers module)

- [x] 4.1 Create `v1alpha1/providers/kubernetes/transformers/sa_resource_transformer.cue` with `#ServiceAccountResourceTransformer` that matches on `requiredResources` containing the ServiceAccount resource FQN
- [x] 4.2 Implement `#transform` to emit a k8s `v1/ServiceAccount` from the SA resource spec
- [x] 4.3 Register `#ServiceAccountResourceTransformer` in `v1alpha1/providers/kubernetes/provider.cue`
- [x] 4.4 Add test data for SA resource transformer in transformer test file
- [x] 4.5 Run `task vet MODULE=providers` to validate transformer

## 5. Role Transformer (providers module)

- [x] 5.1 Create `v1alpha1/providers/kubernetes/transformers/role_transformer.cue` with `#RoleTransformer` that matches on `requiredResources` containing the Role resource FQN
- [x] 5.2 Implement `#transform` for namespace scope: emit list of k8s `Role` + `RoleBinding` with subjects extracted from CUE-referenced identity names
- [x] 5.3 Implement `#transform` for cluster scope: emit list of k8s `ClusterRole` + `ClusterRoleBinding` (no namespace on either)
- [x] 5.4 Register `#RoleTransformer` in `v1alpha1/providers/kubernetes/provider.cue`
- [x] 5.5 Add test data for namespace-scoped Role transformer in transformer test file
- [x] 5.6 Add test data for cluster-scoped Role transformer in transformer test file
- [x] 5.7 Run `task vet MODULE=providers` to validate transformer

## 6. Update INDEX.md

- [x] 6.1 Add new schemas (`#ServiceAccountSchema`, `#PolicyRuleSchema`, `#RoleSubjectSchema`, `#RoleSchema`) to `v1alpha1/INDEX.md`
- [x] 6.2 Add new resources (`#ServiceAccountResource`, `#RoleResource`) to `v1alpha1/INDEX.md`
- [x] 6.3 Add new transformers (`#ServiceAccountResourceTransformer`, `#RoleTransformer`) to `v1alpha1/INDEX.md`

## 7. Validation

- [x] 7.1 Run `task fmt` to format all new files
- [x] 7.2 Run `task vet` to validate all modules
- [x] 7.3 Run `task eval MODULE=resources` to verify evaluated output
- [x] 7.4 Run `task eval MODULE=providers` to verify transformer output
- [x] 7.5 Run `task vet CONCRETE=true` to ensure all changes validate with concreteness check
