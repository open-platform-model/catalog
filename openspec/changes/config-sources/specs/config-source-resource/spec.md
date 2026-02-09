## ADDED Requirements

### Requirement: ConfigSource resource definition

A `#ConfigSourceResource` SHALL be defined as a `core.#Resource` with apiVersion `opmodel.dev/resources/config@v0` and name `config-source`. Its spec SHALL expose a `configSources` field containing a map of named `#ConfigSourceSchema` entries.

#### Scenario: Resource definition structure

- **WHEN** `#ConfigSourceResource` is evaluated
- **THEN** it SHALL unify with `core.#Resource`
- **AND** its `#spec` SHALL define `configSources: [sourceName=string]: #ConfigSourceSchema`
- **AND** each entry SHALL inherit its map key as an identifier

#### Scenario: Multiple config sources on one component

- **WHEN** a component defines multiple entries in `configSources` (e.g., `app-settings`, `db-credentials`, `tls-cert`)
- **THEN** the resource SHALL accept all entries
- **AND** each entry SHALL be independently typed and validated

### Requirement: ConfigSources component helper

A `#ConfigSources` helper SHALL be defined as a `core.#Component` that includes the `#ConfigSourceResource` in its `#resources` map. This enables composition via CUE unification (e.g., `myComponent: workload_resources.#Container & config_resources.#ConfigSources`).

#### Scenario: Composing ConfigSources with Container

- **WHEN** a component unifies `#ConfigSources` with `#Container`
- **THEN** the component's spec SHALL include both `container` and `configSources` fields
- **AND** CUE validation SHALL pass

#### Scenario: ConfigSources without Container

- **WHEN** a component uses `#ConfigSources` without any workload resource
- **THEN** CUE validation SHALL accept the component
- **AND** the component SHALL have `configSources` in its spec

### Requirement: Config source naming

Each config source entry SHALL be identified by its map key within `configSources`. The key SHALL follow the existing OPM `#NameType` conventions (kebab-case).

#### Scenario: Valid config source names

- **WHEN** config sources are named with kebab-case keys (e.g., `app-settings`, `db-credentials`)
- **THEN** the resource SHALL accept the names

#### Scenario: Config source name used in env references

- **WHEN** a container env var specifies `from: { source: "db-credentials", key: "password" }`
- **THEN** the `source` value SHALL correspond to a key in the component's `configSources` map
