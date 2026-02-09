## Purpose

Specifies the Kubernetes ConfigMap transformer, which converts OPM ConfigMap resources into Kubernetes `v1/ConfigMap` objects.

## Requirements

### Requirement: ConfigMap transformer definition

The Kubernetes provider SHALL include a `#ConfigMapTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the ConfigMap resource FQN. It SHALL have no `requiredLabels` and no `requiredTraits`.

#### Scenario: Transformer matches component with ConfigMap resource

- **WHEN** a component has `#ConfigMapResource` in its `#resources`
- **THEN** the `#ConfigMapTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without ConfigMap resource

- **WHEN** a component does not have `#ConfigMapResource` in its `#resources`
- **THEN** the `#ConfigMapTransformer` SHALL not match

### Requirement: ConfigMap output structure

The transformer SHALL emit a valid Kubernetes `v1/ConfigMap` object. The output SHALL include `apiVersion: "v1"`, `kind: "ConfigMap"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and a `data` field populated from the ConfigMap resource spec.

#### Scenario: Single ConfigMap with string data

- **WHEN** a component defines a ConfigMap resource with `data: { "app.conf": "key=value", "settings.json": "{}" }`
- **THEN** the output SHALL be a ConfigMap with `data` containing those exact key-value pairs

#### Scenario: Metadata is derived from context

- **WHEN** a component with ConfigMap resource is transformed with a `#TransformerContext` specifying `namespace: "production"`
- **THEN** the output ConfigMap SHALL have `metadata.namespace: "production"` and `metadata.labels` matching the context labels

### Requirement: Provider registration

The `#ConfigMapTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the ConfigMap transformer

### Requirement: Test data

A test component exercising the ConfigMap transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the ConfigMap transformer test data SHALL validate successfully
