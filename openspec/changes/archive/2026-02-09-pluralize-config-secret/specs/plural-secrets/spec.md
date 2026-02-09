## ADDED Requirements

### Requirement: Secrets resource definition exists

The system SHALL provide a `#SecretsResource` definition in `resources/config/secret.cue` that wraps `#SecretSchema` in a map pattern using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#SecretsResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `apiVersion: "opmodel.dev/resources/config@v0"`, `name: "secrets"`, and `#spec: secrets: [name=string]: schemas.#SecretSchema`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#SecretSchema` is added to a Secrets spec entry
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: Secrets resource carries list-output annotation

`#SecretsResource` SHALL include `"transformer.opmodel.dev/list-output": true` in its `metadata.annotations`.

#### Scenario: Annotation is present

- **WHEN** `#SecretsResource` is evaluated
- **THEN** `#SecretsResource.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

#### Scenario: Annotation propagates to component

- **WHEN** a component includes `#SecretsResource` in its `#resources`
- **THEN** `component.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

### Requirement: Secrets component mixin exists

The system SHALL provide a `#Secrets` component mixin that adds the Secrets resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `config_resources.#Secrets`
- **THEN** the component's `#resources` map SHALL contain the key `opmodel.dev/resources/config@v0#Secrets` with value `#SecretsResource`

#### Scenario: Mixin composes with other resources

- **WHEN** a component embeds both `config_resources.#ConfigMaps` and `config_resources.#Secrets`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

### Requirement: Secrets defaults exist

The system SHALL provide a `#SecretsDefaults` definition that satisfies `#SecretSchema`.

#### Scenario: Defaults include Opaque type

- **WHEN** `#SecretsDefaults` is evaluated
- **THEN** the `type` field SHALL default to `"Opaque"`

### Requirement: Secrets spec exposes a map of named entries

The Secrets spec SHALL expose a `secrets` field containing a map of named entries, where each entry satisfies `#SecretSchema` with an optional `type` string and a `data` map of string key-value pairs.

#### Scenario: Single named Secret with default type

- **WHEN** a component specifies `spec: secrets: "db-creds": data: { "password": "cGFzc3dvcmQ=" }`
- **THEN** CUE validation SHALL accept it and the entry's `type` SHALL default to `"Opaque"`

#### Scenario: Multiple named Secrets with different types

- **WHEN** a component specifies `spec: secrets: { "db-creds": { type: "Opaque", data: { "password": "cGFzc3dvcmQ=" } }, "tls-cert": { type: "kubernetes.io/tls", data: { "tls.crt": "...", "tls.key": "..." } } }`
- **THEN** CUE validation SHALL accept it and both entries SHALL be present with their respective types

#### Scenario: Empty map is valid

- **WHEN** a component specifies `spec: secrets: {}`
- **THEN** CUE validation SHALL accept it
