## 1. Schema Changes (schemas module)

- [x] 1.1 Create `v0/schemas/security.cue` with `#WorkloadIdentitySchema` (name!, automountToken?: bool | *false)
- [x] 1.2 Run `task vet MODULE=schemas` to validate the new schema

## 2. ConfigMap Resource (resources module)

- [x] 2.1 Create `v0/resources/config/` directory
- [x] 2.2 Create `v0/resources/config/configmap.cue` with `#ConfigMapResource`, `#ConfigMap` mixin, and `#ConfigMapDefaults`
- [x] 2.3 Run `task vet MODULE=resources` to validate ConfigMap resource

## 3. Secret Resource (resources module)

- [x] 3.1 Create `v0/resources/config/secret.cue` with `#SecretResource`, `#Secret` mixin, and `#SecretDefaults`
- [x] 3.2 Run `task vet MODULE=resources` to validate Secret resource

## 4. WorkloadIdentity Resource (resources module)

- [x] 4.1 Create `v0/resources/security/` directory
- [x] 4.2 Create `v0/resources/security/workload_identity.cue` with `#WorkloadIdentityResource`, `#WorkloadIdentity` mixin, and `#WorkloadIdentityDefaults`
- [x] 4.3 Run `task vet MODULE=resources` to validate WorkloadIdentity resource

## 5. Validation

- [x] 5.1 Run `task fmt` to format all new files
- [x] 5.2 Run `task vet` to validate all modules
- [x] 5.3 Run `task eval MODULE=resources` to verify evaluated output
