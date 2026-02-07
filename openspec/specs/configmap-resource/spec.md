## Requirements

### Requirement: ConfigMap resource definition exists

The system SHALL provide a `#ConfigMapResource` definition in `resources/config/configmap.cue` that wraps `#ConfigMapSchema` using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#ConfigMapResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `apiVersion: "opmodel.dev/resources/config@v0"`, `name: "config-map"`, and `#spec: configMap: schemas.#ConfigMapSchema`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#ConfigMapSchema` is added to a ConfigMap spec
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: ConfigMap component mixin exists

The system SHALL provide a `#ConfigMap` component mixin that adds the ConfigMap resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `config_resources.#ConfigMap`
- **THEN** the component's `#resources` map SHALL contain the key `opmodel.dev/resources/config@v0#ConfigMap` with value `#ConfigMapResource`

#### Scenario: Mixin composes with other resources

- **WHEN** a component embeds both `workload_resources.#Container` and `config_resources.#ConfigMap`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

### Requirement: ConfigMap defaults exist

The system SHALL provide a `#ConfigMapDefaults` definition that satisfies `#ConfigMapSchema`.

#### Scenario: Defaults are valid

- **WHEN** `#ConfigMapDefaults` is evaluated
- **THEN** it SHALL unify with `#ConfigMapSchema` without error

### Requirement: ConfigMap spec exposes data field

The ConfigMap spec SHALL expose a `configMap` field containing a `data` map of string key-value pairs.

#### Scenario: Valid ConfigMap data

- **WHEN** a component specifies `spec: configMap: data: { "app.conf": "key=value" }`
- **THEN** CUE validation SHALL accept it

#### Scenario: Non-string values rejected

- **WHEN** a component specifies `spec: configMap: data: { "key": 123 }`
- **THEN** CUE validation SHALL reject it at definition time
