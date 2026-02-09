## Purpose

Specifies the Kubernetes Secret transformer, which converts OPM Secret resources into Kubernetes `v1/Secret` objects.

## Requirements

### Requirement: Secret transformer definition

The Kubernetes provider SHALL include a `#SecretTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the Secret resource FQN. It SHALL have no `requiredLabels` and no `requiredTraits`.

#### Scenario: Transformer matches component with Secret resource

- **WHEN** a component has `#SecretResource` in its `#resources`
- **THEN** the `#SecretTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without Secret resource

- **WHEN** a component does not have `#SecretResource` in its `#resources`
- **THEN** the `#SecretTransformer` SHALL not match

### Requirement: Secret output structure

The transformer SHALL emit a valid Kubernetes `v1/Secret` object. The output SHALL include `apiVersion: "v1"`, `kind: "Secret"`, `metadata` with name, namespace, and labels from `#TransformerContext`, a `type` field from the Secret resource spec (defaulting to `"Opaque"`), and a `data` field populated from the Secret resource spec.

#### Scenario: Opaque secret with base64 data

- **WHEN** a component defines a Secret resource with `type: "Opaque"` and `data: { "password": "cGFzc3dvcmQ=" }`
- **THEN** the output SHALL be a Secret with `type: "Opaque"` and `data` containing those key-value pairs

#### Scenario: Default type is Opaque

- **WHEN** a component defines a Secret resource without specifying `type`
- **THEN** the output Secret SHALL have `type: "Opaque"`

#### Scenario: Metadata is derived from context

- **WHEN** a component with Secret resource is transformed with a `#TransformerContext` specifying `namespace: "production"`
- **THEN** the output Secret SHALL have `metadata.namespace: "production"` and `metadata.labels` matching the context labels

### Requirement: Provider registration

The `#SecretTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the Secret transformer

### Requirement: Test data

A test component exercising the Secret transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the Secret transformer test data SHALL validate successfully
