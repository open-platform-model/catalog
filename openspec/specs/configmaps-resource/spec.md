## Requirements

### Requirement: ConfigMaps resource definition exists

The system SHALL provide a `#ConfigMapsResource` definition in `resources/config/configmap.cue` that wraps `#ConfigMapSchema` in a map pattern using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#ConfigMapsResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `apiVersion: "opmodel.dev/resources/config@v0"`, `name: "config-maps"`, and `#spec: configMaps: [name=string]: schemas.#ConfigMapSchema`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#ConfigMapSchema` is added to a ConfigMaps spec entry
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: ConfigMaps resource carries list-output annotation

`#ConfigMapsResource` SHALL include `"transformer.opmodel.dev/list-output": true` in its `metadata.annotations`.

#### Scenario: Annotation is present

- **WHEN** `#ConfigMapsResource` is evaluated
- **THEN** `#ConfigMapsResource.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

#### Scenario: Annotation propagates to component

- **WHEN** a component includes `#ConfigMapsResource` in its `#resources`
- **THEN** `component.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

### Requirement: ConfigMaps component mixin exists

The system SHALL provide a `#ConfigMaps` component mixin that adds the ConfigMaps resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `config_resources.#ConfigMaps`
- **THEN** the component's `#resources` map SHALL contain the key `opmodel.dev/resources/config@v0#ConfigMaps` with value `#ConfigMapsResource`

#### Scenario: Mixin composes with other resources

- **WHEN** a component embeds both `workload_resources.#Container` and `config_resources.#ConfigMaps`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

### Requirement: ConfigMaps defaults exist

The system SHALL provide a `#ConfigMapsDefaults` definition that satisfies `#ConfigMapSchema`.

#### Scenario: Defaults are valid

- **WHEN** `#ConfigMapsDefaults` is evaluated
- **THEN** it SHALL unify with `#ConfigMapSchema` without error

### Requirement: ConfigMaps spec exposes a map of named entries

The ConfigMaps spec SHALL expose a `configMaps` field containing a map of named entries, where each entry satisfies `#ConfigMapSchema` with a `data` map of string key-value pairs.

#### Scenario: Single named ConfigMap

- **WHEN** a component specifies `spec: configMaps: "app-config": data: { "app.conf": "key=value" }`
- **THEN** CUE validation SHALL accept it

#### Scenario: Multiple named ConfigMaps

- **WHEN** a component specifies `spec: configMaps: { "app-config": data: { "app.conf": "key=value" }, "feature-flags": data: { "flags.json": "{}" } }`
- **THEN** CUE validation SHALL accept it and both entries SHALL be present in the spec

#### Scenario: Non-string values rejected

- **WHEN** a component specifies `spec: configMaps: "app-config": data: { "key": 123 }`
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: Empty map is valid

- **WHEN** a component specifies `spec: configMaps: {}`
- **THEN** CUE validation SHALL accept it
