## MODIFIED Requirements

### Requirement: ConfigMap transformer definition

The Kubernetes provider SHALL include a `#ConfigMapTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the ConfigMaps resource FQN (`opmodel.dev/resources/config@v0#ConfigMaps`). It SHALL have no `requiredLabels` and no `requiredTraits`.

#### Scenario: Transformer matches component with ConfigMaps resource

- **WHEN** a component has `#ConfigMapsResource` in its `#resources`
- **THEN** the `#ConfigMapTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without ConfigMaps resource

- **WHEN** a component does not have `#ConfigMapsResource` in its `#resources`
- **THEN** the `#ConfigMapTransformer` SHALL not match

### Requirement: ConfigMap output structure

The transformer SHALL emit a keyed map of valid Kubernetes `v1/ConfigMap` objects, one per entry in the `configMaps` spec. Each output entry SHALL be keyed by the map entry name and SHALL include `apiVersion: "v1"`, `kind: "ConfigMap"`, `metadata` with name derived from the map key, namespace and labels from `#TransformerContext`, and a `data` field populated from the entry.

#### Scenario: Single named ConfigMap

- **WHEN** a component defines a ConfigMaps resource with `configMaps: { "app-config": data: { "app.conf": "key=value", "settings.json": "{}" } }`
- **THEN** the output SHALL be a keyed map containing `"app-config"` with a ConfigMap whose `metadata.name` is `"app-config"` and `data` contains those exact key-value pairs

#### Scenario: Multiple named ConfigMaps

- **WHEN** a component defines a ConfigMaps resource with `configMaps: { "app-config": data: { "app.conf": "key=value" }, "feature-flags": data: { "flags.json": "{}" } }`
- **THEN** the output SHALL be a keyed map containing both `"app-config"` and `"feature-flags"`, each as a complete `v1/ConfigMap` object

#### Scenario: Metadata is derived from context

- **WHEN** a component with ConfigMaps resource is transformed with a `#TransformerContext` specifying `namespace: "production"`
- **THEN** each output ConfigMap SHALL have `metadata.namespace: "production"` and `metadata.labels` matching the context labels

### Requirement: Provider registration

The `#ConfigMapTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the ConfigMap transformer

### Requirement: Test data

A test component exercising the ConfigMap transformer with plural ConfigMaps SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the ConfigMap transformer test data SHALL validate successfully
