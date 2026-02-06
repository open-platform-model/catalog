## Why

Transformer `metadata.apiVersion` values are inconsistent — two use `"transformer.opmodel.dev/workload@v1"` while five use `"opmodel.dev/providers/kubernetes/transformers@v0"`. The provider registry in `v0/providers/kubernetes/provider.cue` uses a third pattern (`"transformer.opmodel.dev/workload@v0"`) as hand-written map keys that match none of the actual transformer FQNs. CUE validation doesn't catch this because `#TransformerMap` keys are `[string]`, not `[#FQNType]`. This undermines Type Safety First and makes it impossible to look up a transformer by its computed `fqn`.

## What Changes

- **BREAKING**: Standardize all transformer `metadata.apiVersion` values to a single convention
- Replace hand-written FQN string keys in `provider.cue` with computed references using CUE parenthesized key expressions (e.g., `(#DeploymentTransformer.metadata.fqn): #DeploymentTransformer`)
- Constrain `#TransformerMap` key type from `[string]` to `[#FQNType]` in `v0/core/transformer.cue`, so CUE rejects non-FQN keys at definition time
- Update `test_data.cue` FQN reference keys to match the standardized FQNs

## Capabilities

### New Capabilities

- `standardize-transformer-apiversion`: Establish a single `apiVersion` convention for all transformer definitions and update all values to match
- `computed-fqn-registry-keys`: Replace hand-written FQN strings in the provider transformer registry with computed references derived from transformer metadata
- `fqn-constrained-transformer-map`: Constrain `#TransformerMap` key type to `#FQNType` so invalid keys are rejected at definition time

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **Affected modules**: `core` (TransformerMap key constraint), `providers` (transformer definitions and provider registry)
- **Breaking change**: FQN values for transformers will change. `#TransformerMap` now rejects non-FQN string keys. Any external code referencing transformers by their old FQN strings or using non-FQN keys will need updating. No API version bump — pre-v1 development.
- **PATCH-level** within the providers module (bug fix: keys don't match computed FQNs)
