## ADDED Requirements

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

### Requirement: WorkloadIdentity resource definition exists

The system SHALL provide a `#WorkloadIdentityResource` definition in `resources/security/workload_identity.cue` that wraps `#WorkloadIdentitySchema` using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#WorkloadIdentityResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `apiVersion: "opmodel.dev/resources/security@v0"`, `name: "workload-identity"`, and `#spec: workloadIdentity: schemas.#WorkloadIdentitySchema`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#WorkloadIdentitySchema` is added to a WorkloadIdentity spec
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: WorkloadIdentity component mixin exists

The system SHALL provide a `#WorkloadIdentity` component mixin that adds the WorkloadIdentity resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `security_resources.#WorkloadIdentity`
- **THEN** the component's `#resources` map SHALL contain the key `opmodel.dev/resources/security@v0#WorkloadIdentity` with value `#WorkloadIdentityResource`

#### Scenario: Mixin composes with Container resource

- **WHEN** a component embeds both `workload_resources.#Container` and `security_resources.#WorkloadIdentity`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

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
