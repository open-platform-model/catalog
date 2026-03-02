## Purpose

Defines the Kubernetes transformer for the standalone ServiceAccount resource, converting it to a `v1/ServiceAccount` object. Separate from the WorkloadIdentity trait transformer.

## Requirements

### Requirement: ServiceAccount resource transformer definition

The Kubernetes provider SHALL include a `#ServiceAccountResourceTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the ServiceAccount resource FQN. It SHALL have no `requiredLabels`, no `requiredTraits`, and empty `optionalTraits`.

#### Scenario: Transformer matches component with ServiceAccount resource

- **WHEN** a component has `#ServiceAccountResource` in its `#resources`
- **THEN** the `#ServiceAccountResourceTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without ServiceAccount resource

- **WHEN** a component does not have `#ServiceAccountResource` in its `#resources`
- **THEN** the `#ServiceAccountResourceTransformer` SHALL not match

### Requirement: ServiceAccount resource transformer output structure

The transformer SHALL emit a valid Kubernetes `v1/ServiceAccount` object. The output SHALL include `apiVersion: "v1"`, `kind: "ServiceAccount"`, and `metadata` with name, namespace, and labels from `#TransformerContext`. The `automountServiceAccountToken` field SHALL be set from the ServiceAccount resource's `automountToken` field.

#### Scenario: ServiceAccount with token automount disabled

- **WHEN** a component defines a ServiceAccount resource with `name: "ci-bot"` and `automountToken: false`
- **THEN** the output SHALL be a ServiceAccount with `metadata.name: "ci-bot"` and `automountServiceAccountToken: false`

#### Scenario: ServiceAccount with default automount

- **WHEN** a component defines a ServiceAccount resource with `name: "ci-bot"` without specifying `automountToken`
- **THEN** the output ServiceAccount SHALL have `automountServiceAccountToken: false` (from defaults)

### Requirement: ServiceAccount resource transformer is independent from WorkloadIdentity transformer

The `#ServiceAccountResourceTransformer` SHALL be a separate transformer from the existing `#ServiceAccountTransformer` (which handles WorkloadIdentity traits). They SHALL have different FQNs and different matching criteria.

#### Scenario: Both transformers coexist

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** both `#ServiceAccountTransformer` (trait-based) and `#ServiceAccountResourceTransformer` (resource-based) SHALL be registered in the provider's `transformers` map with distinct FQN keys

### Requirement: Provider registration

The `#ServiceAccountResourceTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the ServiceAccount resource transformer

### Requirement: Test data

A test component exercising the ServiceAccount resource transformer SHALL exist in the transformers test data. The test component SHALL use `#resources` to attach `#ServiceAccountResource`.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the ServiceAccount resource transformer test data SHALL validate successfully
