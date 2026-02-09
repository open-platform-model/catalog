## ADDED Requirements

### Requirement: ConfigSource type discriminator

The `#ConfigSourceSchema` SHALL have a required `type` field that distinguishes between sensitive and non-sensitive configuration. The allowed values SHALL be `"config"` (non-sensitive) and `"secret"` (sensitive).

#### Scenario: Config type source

- **WHEN** a config source is defined with `type: "config"`
- **THEN** the schema SHALL accept the definition
- **AND** providers SHALL treat the data as non-sensitive (e.g., K8s ConfigMap)

#### Scenario: Secret type source

- **WHEN** a config source is defined with `type: "secret"`
- **THEN** the schema SHALL accept the definition
- **AND** providers SHALL treat the data as sensitive (e.g., K8s Secret)

#### Scenario: Invalid type rejected

- **WHEN** a config source is defined with a type other than `"config"` or `"secret"`
- **THEN** CUE validation SHALL reject the definition at evaluation time

### Requirement: Inline data

The `#ConfigSourceSchema` SHALL support an optional `data` field containing string key-value pairs for inline configuration values.

#### Scenario: Config source with inline data

- **WHEN** a config source specifies `data` with key-value string pairs
- **THEN** the schema SHALL accept the definition
- **AND** providers SHALL use the data to create platform-native config resources

#### Scenario: Empty data map

- **WHEN** a config source specifies `data` as an empty map
- **THEN** the schema SHALL accept the definition

### Requirement: External reference

The `#ConfigSourceSchema` SHALL support an optional `externalRef` field for referencing configuration resources that exist outside the module. The `externalRef` SHALL contain a required `name` field (plain string).

#### Scenario: External secret reference

- **WHEN** a config source specifies `externalRef` with a `name`
- **THEN** the schema SHALL accept the definition
- **AND** providers SHALL NOT create a new resource but SHALL use the name when wiring references

#### Scenario: External ref without name rejected

- **WHEN** a config source specifies `externalRef` without a `name`
- **THEN** CUE validation SHALL reject the definition

### Requirement: Data or external ref exclusivity

A config source SHALL specify either `data` or `externalRef`, but not both. At least one MUST be present.

#### Scenario: Both data and externalRef specified

- **WHEN** a config source specifies both `data` and `externalRef`
- **THEN** CUE validation SHALL reject the definition

#### Scenario: Neither data nor externalRef specified

- **WHEN** a config source specifies neither `data` nor `externalRef`
- **THEN** CUE validation SHALL reject the definition

### Requirement: Env from reference schema

The `#ContainerSchema.env` SHALL support an optional `from` field on each environment variable entry, alongside the existing `value` field. The `from` field SHALL contain required `source` (string naming a config source) and `key` (string naming a key within that source).

#### Scenario: Env var with literal value

- **WHEN** an env var specifies `value: "some-string"`
- **THEN** the schema SHALL accept it (backward compatible)
- **AND** providers SHALL emit a literal environment variable

#### Scenario: Env var with from reference

- **WHEN** an env var specifies `from: { source: "my-secret", key: "password" }`
- **THEN** the schema SHALL accept it
- **AND** providers SHALL resolve the reference to the named config source and emit platform-native secret/config injection

#### Scenario: Env var with both value and from rejected

- **WHEN** an env var specifies both `value` and `from`
- **THEN** CUE validation SHALL reject the definition

#### Scenario: Env var with neither value nor from rejected

- **WHEN** an env var specifies neither `value` nor `from`
- **THEN** CUE validation SHALL reject the definition

### Requirement: Platform-agnostic schema

The `#ConfigSourceSchema` and the env `from` reference SHALL NOT contain any platform-specific fields. The schema SHALL express intent ("this is a secret named X with key Y") and leave platform-specific concerns to provider transformers.

#### Scenario: Schema contains no K8s-specific fields

- **WHEN** the `#ConfigSourceSchema` is evaluated
- **THEN** it SHALL NOT reference Kubernetes concepts such as namespace, apiVersion, or kind
- **AND** the `from` field SHALL use only `source` and `key` — no `secretKeyRef`, `configMapKeyRef`, or similar platform terms
