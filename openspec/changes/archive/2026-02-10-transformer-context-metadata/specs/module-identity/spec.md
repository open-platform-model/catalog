## ADDED Requirements

### Requirement: Module identity label on Module metadata

`#Module.metadata.labels` SHALL include the label `module.opmodel.dev/uuid` with its value set to the string representation of `metadata.identity`.

#### Scenario: Module carries module-id label

- **WHEN** a valid `#Module` is evaluated
- **THEN** `metadata.labels["module.opmodel.dev/uuid"]` SHALL equal the string value of `metadata.identity`

#### Scenario: Module-id is a valid UUID string

- **WHEN** a valid `#Module` is evaluated
- **THEN** `metadata.labels["module.opmodel.dev/uuid"]` SHALL satisfy `#UUIDType`

#### Scenario: Module-id label is inherited by ModuleRelease

- **WHEN** a valid `#ModuleRelease` references a `#Module`
- **THEN** `#ModuleRelease.metadata.labels["module.opmodel.dev/uuid"]` SHALL equal the module's `metadata.identity`

#### Scenario: Module-id label propagates through TransformerContext to rendered resources

- **WHEN** a `#TransformerContext` is constructed with a `#ModuleRelease`'s metadata
- **THEN** the `module.opmodel.dev/uuid` label SHALL appear in `moduleLabels`
- **AND** SHALL appear in the merged `labels` field applied to rendered provider resources

### Requirement: Module identity label is non-overridable

The `module.opmodel.dev/uuid` label SHALL be computed from `metadata.identity`. Module authors MUST NOT be able to set it to a different value.

#### Scenario: Author attempts to override module-id label

- **WHEN** a module definition includes `metadata.labels: {"module.opmodel.dev/uuid": "custom-value"}` that differs from the computed identity
- **THEN** CUE evaluation SHALL fail with a conflict error
