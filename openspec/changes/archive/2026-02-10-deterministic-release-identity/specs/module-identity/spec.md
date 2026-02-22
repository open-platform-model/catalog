## ADDED Requirements

### Requirement: OPM UUID v5 namespace constant

The `core` module SHALL define a hidden definition `OPMNamespace` in `common.cue` containing a fixed UUID string. This UUID serves as the RFC 4122 namespace for all OPM identity computations via `uuid.SHA1`. It MUST never change once published.

#### Scenario: Namespace constant is a valid UUID

- **WHEN** `OPMNamespace` is evaluated
- **THEN** it SHALL be a valid UUID v4 string in standard format (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

#### Scenario: Namespace constant is stable

- **WHEN** the `core` module is published at any version
- **THEN** `OPMNamespace` SHALL have the same value as in every prior version

### Requirement: UUID type constraint

The `core` module SHALL define a `#UUIDType` constraint in `common.cue` that validates strings as RFC 4122 UUIDs in standard format.

#### Scenario: Valid UUID passes constraint

- **WHEN** a string in standard UUID format (e.g., `"a1b2c3d4-e5f6-7890-abcd-ef1234567890"`) is unified with `#UUIDType`
- **THEN** validation SHALL succeed

#### Scenario: Invalid string fails constraint

- **WHEN** a non-UUID string (e.g., `"not-a-uuid"`) is unified with `#UUIDType`
- **THEN** validation SHALL fail

### Requirement: Module identity computation

`#Module.metadata` SHALL include a computed `uuid` field of type `#UUIDType`. The value SHALL be `uuid.SHA1(OPMNamespace, "{fqn}:{version}")` where `fqn` and `version` are the module's existing metadata fields.

#### Scenario: Same module produces same identity

- **WHEN** two `#Module` instances have identical `metadata.fqn` and `metadata.version`
- **THEN** their `metadata.identity` values SHALL be identical

#### Scenario: Different version produces different identity

- **WHEN** a `#Module` has `metadata.version: "0.1.0"`
- **AND** another `#Module` has the same `fqn` but `metadata.version: "0.2.0"`
- **THEN** their `metadata.identity` values SHALL differ

#### Scenario: Different FQN produces different identity

- **WHEN** two `#Module` instances have different `metadata.fqn` values
- **THEN** their `metadata.identity` values SHALL differ regardless of version

#### Scenario: Identity is a valid UUID

- **WHEN** any valid `#Module` is evaluated
- **THEN** `metadata.identity` SHALL satisfy `#UUIDType`

### Requirement: Module identity is non-settable

Module authors MUST NOT be able to override `metadata.identity`. The field SHALL be computed from `fqn` and `version` — it is not a user input.

#### Scenario: Author attempts to set identity

- **WHEN** a module definition includes an explicit `metadata.uuid: "custom-value"` that differs from the computed value
- **THEN** CUE evaluation SHALL fail with a conflict error

### Requirement: Release identity computation

`#ModuleRelease.metadata` SHALL include a computed `uuid` field of type `#UUIDType`. The value SHALL be `uuid.SHA1(OPMNamespace, "{fqn}:{name}:{namespace}")` where `fqn` comes from the referenced module and `name`/`namespace` are the release's own metadata fields. Version SHALL NOT be an input to the release uuid.

#### Scenario: Same release slot produces same identity across versions

- **WHEN** a `#ModuleRelease` references module version `"0.1.0"` with release name `"blog"` in namespace `"default"`
- **AND** another `#ModuleRelease` references the same module at version `"0.2.0"` with the same release name and namespace
- **THEN** their `metadata.identity` values SHALL be identical

#### Scenario: Different release name produces different identity

- **WHEN** two `#ModuleRelease` instances reference the same module in the same namespace
- **AND** they have different `metadata.name` values
- **THEN** their `metadata.identity` values SHALL differ

#### Scenario: Different namespace produces different identity

- **WHEN** two `#ModuleRelease` instances reference the same module with the same release name
- **AND** they target different namespaces
- **THEN** their `metadata.identity` values SHALL differ

#### Scenario: Release identity is a valid UUID

- **WHEN** any valid `#ModuleRelease` is evaluated
- **THEN** `metadata.identity` SHALL satisfy `#UUIDType`

### Requirement: Release identity is non-settable

Release consumers MUST NOT be able to override `metadata.identity`. The field SHALL be computed from `fqn`, `name`, and `namespace`.

#### Scenario: Consumer attempts to set identity

- **WHEN** a release definition includes an explicit `metadata.uuid: "custom-value"` that differs from the computed value
- **THEN** CUE evaluation SHALL fail with a conflict error

### Requirement: Backwards compatibility with existing modules

Adding `metadata.identity` MUST NOT break existing valid module or release definitions. No existing required fields change, and no existing computed fields are modified.

#### Scenario: Existing module validates without changes

- **WHEN** an existing valid `#Module` definition (without `metadata.identity`) is evaluated against the updated schema
- **THEN** validation SHALL succeed
- **AND** `metadata.identity` SHALL be automatically computed

#### Scenario: Existing release validates without changes

- **WHEN** an existing valid `#ModuleRelease` definition (without `metadata.identity`) is evaluated against the updated schema
- **THEN** validation SHALL succeed
- **AND** `metadata.identity` SHALL be automatically computed
