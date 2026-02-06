## ADDED Requirements

### Requirement: Provider transformer registry uses computed FQN keys

The `transformers` map in provider definitions SHALL use computed FQN references as keys instead of hand-written string literals. Each key SHALL be a parenthesized CUE expression referencing the transformer's `metadata.fqn` field.

Example:
```cue
transformers: {
    (k8s_transformers.#DeploymentTransformer.metadata.fqn): k8s_transformers.#DeploymentTransformer
}
```

This ensures the map key always matches the transformer's own computed FQN, eliminating drift between keys and definitions.

#### Scenario: Registry key matches transformer FQN

- **WHEN** inspecting a key in `#Provider.transformers`
- **THEN** the key string SHALL equal the corresponding transformer definition's `metadata.fqn` value

#### Scenario: Deployment transformer registry key is computed

- **WHEN** inspecting the Kubernetes provider's `transformers` map entry for the deployment transformer
- **THEN** the key SHALL be the computed `fqn` from `#DeploymentTransformer.metadata.fqn`, not a hand-written string literal

#### Scenario: All seven registry keys are computed references

- **WHEN** inspecting all keys in the Kubernetes provider's `transformers` map
- **THEN** all seven keys SHALL be parenthesized CUE expressions referencing their respective transformer's `metadata.fqn`

### Requirement: Test data FQN references match standardized values

All FQN string literals used as map keys in `test_data.cue` (for `#resources`, `#traits`, or any transformer reference) SHALL match the actual computed `fqn` values of the referenced definitions.

#### Scenario: Test data resource FQN keys are valid

- **WHEN** inspecting resource map keys in test components within `test_data.cue`
- **THEN** each key SHALL match the `fqn` computed by the referenced resource definition

#### Scenario: Test data trait FQN keys are valid

- **WHEN** inspecting trait map keys in test components within `test_data.cue`
- **THEN** each key SHALL match the `fqn` computed by the referenced trait definition

#### Scenario: CUE validation passes after update

- **WHEN** running `cue vet ./...` in the providers module
- **THEN** validation SHALL pass with zero errors
