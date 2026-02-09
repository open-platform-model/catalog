## 1. Pluralize ConfigMap resource

- [x] 1.1 Rewrite `v0/resources/config/configmap.cue`: rename `#ConfigMapResource` → `#ConfigMapsResource`, change `metadata.name` to `"config-maps"`, add `"transformer.opmodel.dev/list-output": true` annotation, change `#spec` to `configMaps: [name=string]: schemas.#ConfigMapSchema`
- [x] 1.2 Rename composition struct `#ConfigMap` → `#ConfigMaps` with updated FQN reference
- [x] 1.3 Rename `#ConfigMapDefaults` → `#ConfigMapsDefaults`
- [x] 1.4 Run `task vet MODULE=resources` to verify the resource module validates

## 2. Pluralize Secret resource

- [x] 2.1 Rewrite `v0/resources/config/secret.cue`: rename `#SecretResource` → `#SecretsResource`, change `metadata.name` to `"secrets"`, add `"transformer.opmodel.dev/list-output": true` annotation, change `#spec` to `secrets: [name=string]: schemas.#SecretSchema & {type: string | *"Opaque"}`
- [x] 2.2 Rename composition struct `#Secret` → `#Secrets` with updated FQN reference
- [x] 2.3 Rename `#SecretDefaults` → `#SecretsDefaults`
- [x] 2.4 Run `task vet MODULE=resources` to verify the resource module validates

## 3. Update ConfigMap transformer

- [x] 3.1 Update `v0/providers/kubernetes/transformers/configmap_transformer.cue`: change `requiredResources` FQN to `opmodel.dev/resources/config@v0#ConfigMaps`, update `#transform` to iterate `configMaps` map and emit keyed output (one K8s ConfigMap per entry, matching PVC transformer pattern)
- [x] 3.2 Update `_testConfigMapComponent` in `v0/providers/kubernetes/transformers/test_data.cue`: change `#resources` FQN key and `spec` to use plural `configMaps` map with at least one named entry

## 4. Update Secret transformer

- [x] 4.1 Update `v0/providers/kubernetes/transformers/secret_transformer.cue`: change `requiredResources` FQN to `opmodel.dev/resources/config@v0#Secrets`, update `#transform` to iterate `secrets` map and emit keyed output (one K8s Secret per entry with `type` and `data`)
- [x] 4.2 Update `_testSecretComponent` in `v0/providers/kubernetes/transformers/test_data.cue`: change `#resources` FQN key and `spec` to use plural `secrets` map with at least one named entry

## 5. Update provider registration

- [x] 5.1 Verify `v0/providers/kubernetes/provider.cue` transformer FQN keys auto-update (they derive from transformer metadata, not resource metadata — confirm no manual change needed)

## 6. Validation

- [x] 6.1 Run `task fmt` — all CUE files formatted
- [x] 6.2 Run `task vet` — all modules validate
- [x] 6.3 Run `task eval MODULE=providers OUTPUT=provider-output.cue` and verify ConfigMap/Secret transformer output uses keyed map structure
