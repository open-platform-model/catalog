## Requirements

### Requirement: WorkloadIdentity schema exists

The system SHALL provide a `#WorkloadIdentitySchema` definition in `schemas/security.cue` with a required `name` field and an optional `automountToken` field.

#### Scenario: Schema structure

- **WHEN** `#WorkloadIdentitySchema` is evaluated
- **THEN** it SHALL require `name!: string` and provide `automountToken?: bool | *false`

#### Scenario: Missing name rejected

- **WHEN** a WorkloadIdentity spec omits the `name` field
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: automountToken defaults to false

- **WHEN** a WorkloadIdentity spec provides only `name: "my-service"`
- **THEN** `automountToken` SHALL default to `false`

### Requirement: WorkloadIdentity defaults exist

The system SHALL provide a `#WorkloadIdentityDefaults` definition that satisfies `#WorkloadIdentitySchema`.

#### Scenario: Defaults are valid

- **WHEN** `#WorkloadIdentityDefaults` is evaluated
- **THEN** it SHALL unify with `#WorkloadIdentitySchema` without error and `automountToken` SHALL default to `false`

### Requirement: WorkloadIdentity is provider-agnostic

The `#WorkloadIdentitySchema` SHALL NOT contain any provider-specific fields. It expresses the intent of having a named identity, not how that identity is realized.

#### Scenario: No K8s-specific fields

- **WHEN** `#WorkloadIdentitySchema` is inspected
- **THEN** it SHALL NOT contain fields like `serviceAccountName`, `iamRole`, `annotations`, or any other provider-specific concept
