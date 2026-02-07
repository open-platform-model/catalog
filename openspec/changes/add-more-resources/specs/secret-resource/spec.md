## ADDED Requirements

### Requirement: Secret resource definition exists

The system SHALL provide a `#SecretResource` definition in `resources/config/secret.cue` that wraps `#SecretSchema` using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#SecretResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `apiVersion: "opmodel.dev/resources/config@v0"`, `name: "secret"`, and `#spec: secret: schemas.#SecretSchema`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#SecretSchema` is added to a Secret spec
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: Secret component mixin exists

The system SHALL provide a `#Secret` component mixin that adds the Secret resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `config_resources.#Secret`
- **THEN** the component's `#resources` map SHALL contain the key `opmodel.dev/resources/config@v0#Secret` with value `#SecretResource`

#### Scenario: Mixin composes with ConfigMap

- **WHEN** a component embeds both `config_resources.#ConfigMap` and `config_resources.#Secret`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

### Requirement: Secret defaults exist

The system SHALL provide a `#SecretDefaults` definition that satisfies `#SecretSchema`.

#### Scenario: Defaults include Opaque type

- **WHEN** `#SecretDefaults` is evaluated
- **THEN** the `type` field SHALL default to `"Opaque"`

### Requirement: Secret spec exposes type and data fields

The Secret spec SHALL expose a `secret` field containing an optional `type` string and a `data` map of string key-value pairs (base64-encoded by convention).

#### Scenario: Valid Secret with default type

- **WHEN** a component specifies `spec: secret: data: { "password": "cGFzc3dvcmQ=" }`
- **THEN** CUE validation SHALL accept it and `type` SHALL default to `"Opaque"`

#### Scenario: Valid Secret with explicit type

- **WHEN** a component specifies `spec: secret: { type: "kubernetes.io/tls", data: { "tls.crt": "...", "tls.key": "..." } }`
- **THEN** CUE validation SHALL accept it
