## 1. Schema Changes (schemas module)

- [ ] 1.1 Create `v0/schemas/security.cue` with `#WorkloadIdentitySchema` (name!, automountToken?: bool | *false)
- [ ] 1.2 Run `task vet MODULE=schemas` to validate the new schema

## 2. ConfigMap Resource (resources module)

- [ ] 2.1 Create `v0/resources/config/` directory
- [ ] 2.2 Create `v0/resources/config/configmap.cue` with `#ConfigMapResource`, `#ConfigMap` mixin, and `#ConfigMapDefaults`
- [ ] 2.3 Run `task vet MODULE=resources` to validate ConfigMap resource

## 3. Secret Resource (resources module)

- [ ] 3.1 Create `v0/resources/config/secret.cue` with `#SecretResource`, `#Secret` mixin, and `#SecretDefaults`
- [ ] 3.2 Run `task vet MODULE=resources` to validate Secret resource

## 4. WorkloadIdentity Resource (resources module)

- [ ] 4.1 Create `v0/resources/security/` directory
- [ ] 4.2 Create `v0/resources/security/workload_identity.cue` with `#WorkloadIdentityResource`, `#WorkloadIdentity` mixin, and `#WorkloadIdentityDefaults`
- [ ] 4.3 Run `task vet MODULE=resources` to validate WorkloadIdentity resource

## 5. Validation

- [ ] 5.1 Run `task fmt` to format all new files
- [ ] 5.2 Run `task vet` to validate all modules
- [ ] 5.3 Run `task eval MODULE=resources` to verify evaluated output
