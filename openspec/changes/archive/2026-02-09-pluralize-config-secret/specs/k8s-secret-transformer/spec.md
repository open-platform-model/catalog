## MODIFIED Requirements

### Requirement: Secret transformer definition

The Kubernetes provider SHALL include a `#SecretTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the Secrets resource FQN (`opmodel.dev/resources/config@v0#Secrets`). It SHALL have no `requiredLabels` and no `requiredTraits`.

#### Scenario: Transformer matches component with Secrets resource

- **WHEN** a component has `#SecretsResource` in its `#resources`
- **THEN** the `#SecretTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without Secrets resource

- **WHEN** a component does not have `#SecretsResource` in its `#resources`
- **THEN** the `#SecretTransformer` SHALL not match

### Requirement: Secret output structure

The transformer SHALL emit a keyed map of valid Kubernetes `v1/Secret` objects, one per entry in the `secrets` spec. Each output entry SHALL be keyed by the map entry name and SHALL include `apiVersion: "v1"`, `kind: "Secret"`, `metadata` with name derived from the map key, namespace and labels from `#TransformerContext`, a `type` field from the entry (defaulting to `"Opaque"`), and a `data` field populated from the entry.

#### Scenario: Single named Opaque Secret

- **WHEN** a component defines a Secrets resource with `secrets: { "db-creds": { type: "Opaque", data: { "password": "cGFzc3dvcmQ=" } } }`
- **THEN** the output SHALL be a keyed map containing `"db-creds"` with a Secret whose `metadata.name` is `"db-creds"`, `type` is `"Opaque"`, and `data` contains those key-value pairs

#### Scenario: Multiple named Secrets with different types

- **WHEN** a component defines a Secrets resource with `secrets: { "db-creds": { data: { "password": "cGFzc3dvcmQ=" } }, "tls-cert": { type: "kubernetes.io/tls", data: { "tls.crt": "...", "tls.key": "..." } } }`
- **THEN** the output SHALL be a keyed map containing both `"db-creds"` (with `type: "Opaque"`) and `"tls-cert"` (with `type: "kubernetes.io/tls"`), each as a complete `v1/Secret` object

#### Scenario: Default type is Opaque

- **WHEN** a component defines a Secrets entry without specifying `type`
- **THEN** the output Secret for that entry SHALL have `type: "Opaque"`

#### Scenario: Metadata is derived from context

- **WHEN** a component with Secrets resource is transformed with a `#TransformerContext` specifying `namespace: "production"`
- **THEN** each output Secret SHALL have `metadata.namespace: "production"` and `metadata.labels` matching the context labels

### Requirement: Provider registration

The `#SecretTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the Secret transformer

### Requirement: Test data

A test component exercising the Secret transformer with plural Secrets SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the Secret transformer test data SHALL validate successfully
