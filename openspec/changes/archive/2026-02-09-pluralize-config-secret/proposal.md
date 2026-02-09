## Why

`#ConfigMapResource` and `#SecretResource` are singular — each component can declare exactly one ConfigMap and one Secret. In practice, workloads routinely need multiple ConfigMaps (app config, feature flags, env-specific overrides) and multiple Secrets (TLS certs, DB credentials, API keys). The plural map pattern already exists for `#VolumesResource` (`volumes: [string]: #VolumeSchema`), and converting ConfigMap and Secret to the same pattern brings consistency and removes an artificial limitation.

## What Changes

- **BREAKING**: Rename `#ConfigMapResource` → `#ConfigMapsResource` with `metadata.name: "config-maps"` and `#spec: configMaps: [name=string]: #ConfigMapSchema`
- **BREAKING**: Rename `#SecretResource` → `#SecretsResource` with `metadata.name: "secrets"` and `#spec: secrets: [name=string]: #SecretSchema`
- **BREAKING**: Rename composition structs `#ConfigMap` → `#ConfigMaps`, `#Secret` → `#Secrets`
- **BREAKING**: Rename defaults `#ConfigMapDefaults` → `#ConfigMapsDefaults`, `#SecretDefaults` → `#SecretsDefaults`
- Add `"transformer.opmodel.dev/list-output": true` annotation to both new plural resources (per the `allow-list-output` change pattern)
- Update `#ConfigMapTransformer` and `#SecretTransformer` to iterate the map and emit keyed output (mirroring `#PVCTransformer`)
- Update transformer FQN references, required resources, test data, and provider registration

## Capabilities

### New Capabilities

- `plural-configmaps`: Spec for the pluralized ConfigMap resource — map-based `#spec`, renamed definitions, list-output annotation, composition struct, and defaults
- `plural-secrets`: Spec for the pluralized Secret resource — map-based `#spec`, renamed definitions, list-output annotation, composition struct, and defaults

### Modified Capabilities

- `k8s-configmap-transformer`: Transformer changes from single-object output to keyed map output iterating over `configMaps` entries
- `k8s-secret-transformer`: Transformer changes from single-object output to keyed map output iterating over `secrets` entries

## Impact

- **resources/config module**: `configmap.cue` and `secret.cue` rewritten with plural definitions
- **providers/kubernetes module**: `configmap_transformer.cue`, `secret_transformer.cue`, `test_data.cue`, and `provider.cue` updated for new FQNs and map-based output
- **schemas module**: No changes — `#ConfigMapSchema` and `#SecretSchema` remain per-item schemas
- **core module**: No changes — annotation propagation and `#Component` assembly already support this
- **Volume schema**: `#VolumeSchema.configMap?` and `#VolumeSchema.secret?` fields are unaffected — they are volume source references, not resource definitions
- **Blueprints**: None currently compose ConfigMap or Secret resources — no changes
- **Examples**: No existing examples use ConfigMap or Secret — no changes
- **Sibling dependency**: Relies on the `allow-list-output` change establishing the `transformer.opmodel.dev/list-output` annotation pattern
- **SemVer**: MINOR at v0 (breaking changes are expected pre-v1)
