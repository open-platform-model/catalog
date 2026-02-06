## ADDED Requirements

### Requirement: TransformerMap keys constrained to FQNType

`#TransformerMap` in `v0/core/transformer.cue` SHALL constrain its keys to `#FQNType` instead of `string`. The definition SHALL be:

```cue
#TransformerMap: [#FQNType]: #Transformer
```

This ensures that any map using `#TransformerMap` (currently `#Provider.transformers`) rejects non-FQN keys at CUE validation time.

#### Scenario: Valid FQN key accepted

- **WHEN** a `#TransformerMap` entry uses a key matching `#FQNType` (e.g., `"opmodel.dev/providers/kubernetes/transformers@v0#DeploymentTransformer"`)
- **THEN** CUE validation SHALL pass

#### Scenario: Non-FQN string key rejected

- **WHEN** a `#TransformerMap` entry uses a key that does not match `#FQNType` (e.g., `"deployment"` or `"some-arbitrary-string"`)
- **THEN** CUE validation SHALL fail at definition time

#### Scenario: Key with wrong FQN format rejected

- **WHEN** a `#TransformerMap` entry uses a key like `"transformer.opmodel.dev/workload@v0"` (missing the `#Name` segment)
- **THEN** CUE validation SHALL fail at definition time

#### Scenario: Provider transformers map inherits constraint

- **WHEN** `#Provider.transformers` is typed as `#TransformerMap`
- **THEN** all keys in `#Provider.transformers` SHALL be validated against `#FQNType`
