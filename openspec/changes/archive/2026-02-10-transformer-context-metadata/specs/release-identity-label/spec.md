## ADDED Requirements

### Requirement: Release identity label on ModuleRelease metadata

`#ModuleRelease.metadata.labels` SHALL include the label `module-release.opmodel.dev/uuid` with its value set to the string representation of `metadata.identity`. This label is computed and non-overridable, mirroring the pattern used by `module.opmodel.dev/uuid` on `#Module`.

#### Scenario: ModuleRelease carries release-id label

- **WHEN** a valid `#ModuleRelease` is evaluated
- **THEN** `metadata.labels["module-release.opmodel.dev/uuid"]` SHALL equal the string value of `metadata.identity`

#### Scenario: Release-id is a valid UUID string

- **WHEN** a valid `#ModuleRelease` is evaluated
- **THEN** `metadata.labels["module-release.opmodel.dev/uuid"]` SHALL satisfy `#UUIDType`

#### Scenario: Same release slot produces same release-id across module versions

- **WHEN** a `#ModuleRelease` with name `"blog"` in namespace `"default"` references module version `"0.1.0"`
- **AND** another `#ModuleRelease` with the same name and namespace references the same module at version `"0.2.0"`
- **THEN** both SHALL have identical `metadata.labels["module-release.opmodel.dev/uuid"]` values

#### Scenario: Different release names produce different release-id

- **WHEN** two `#ModuleRelease` instances reference the same module in the same namespace but have different `metadata.name` values
- **THEN** their `metadata.labels["module-release.opmodel.dev/uuid"]` values SHALL differ

#### Scenario: Release-id label propagates through TransformerContext to K8s resources

- **WHEN** a `#TransformerContext` is constructed with a `#ModuleRelease`'s metadata
- **THEN** the `module-release.opmodel.dev/uuid` label SHALL appear in `moduleLabels`
- **AND** SHALL appear in the merged `labels` field applied to rendered K8s resources

### Requirement: Release-id label coexists with inherited module-id

`#ModuleRelease.metadata.labels` inherits labels from `#Module.metadata.labels` (including `module.opmodel.dev/uuid`). The `release-id` label SHALL coexist with the inherited `module-id` label without conflict.

#### Scenario: Both module-id and release-id present on release

- **WHEN** a valid `#ModuleRelease` is evaluated
- **THEN** `metadata.labels` SHALL contain both `module.opmodel.dev/uuid` and `module-release.opmodel.dev/uuid`
- **AND** their values SHALL differ (module-id is derived from fqn+version, release-id from fqn+name+namespace)
