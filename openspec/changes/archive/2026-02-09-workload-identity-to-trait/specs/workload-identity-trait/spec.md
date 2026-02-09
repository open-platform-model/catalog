## ADDED Requirements

### Requirement: WorkloadIdentity trait definition exists

The system SHALL provide a `#WorkloadIdentityTrait` definition in `traits/security/workload_identity.cue` that wraps `#WorkloadIdentitySchema` using the `core.#Trait` pattern with `appliesTo` binding to `#ContainerResource`.

#### Scenario: Trait definition structure

- **WHEN** `#WorkloadIdentityTrait` is evaluated
- **THEN** it SHALL satisfy `core.#Trait` with `apiVersion: "opmodel.dev/traits/security@v0"`, `name: "workload-identity"`, `appliesTo: [workload_resources.#ContainerResource]`, and `#spec: workloadIdentity: schemas.#WorkloadIdentitySchema`

#### Scenario: Trait definition is closed

- **WHEN** a field not in `#WorkloadIdentitySchema` is added to a WorkloadIdentity spec
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: Trait FQN is correct

- **WHEN** `#WorkloadIdentityTrait.metadata.fqn` is evaluated
- **THEN** it SHALL equal `"opmodel.dev/traits/security@v0#WorkloadIdentity"`

### Requirement: WorkloadIdentity component mixin registers as trait

The system SHALL provide a `#WorkloadIdentity` component mixin in `traits/security/workload_identity.cue` that adds the WorkloadIdentity trait FQN to a component's `#traits` map.

#### Scenario: Mixin adds trait to component

- **WHEN** a component embeds `security_traits.#WorkloadIdentity`
- **THEN** the component's `#traits` map SHALL contain the key `opmodel.dev/traits/security@v0#WorkloadIdentity` with value `#WorkloadIdentityTrait`

#### Scenario: Mixin composes with Container resource and other traits

- **WHEN** a component embeds `workload_resources.#Container`, `security_traits.#WorkloadIdentity`, and `security_traits.#SecurityContext`
- **THEN** the Container resource FQN SHALL be in `#resources`, and both security trait FQNs SHALL be in `#traits` without conflict

### Requirement: WorkloadIdentity defaults exist

The system SHALL provide a `#WorkloadIdentityDefaults` definition in `traits/security/workload_identity.cue` that satisfies `#WorkloadIdentitySchema`.

#### Scenario: Defaults are valid

- **WHEN** `#WorkloadIdentityDefaults` is evaluated
- **THEN** it SHALL unify with `#WorkloadIdentitySchema` without error and `automountToken` SHALL be `false`

### Requirement: WorkloadIdentity resource definition is removed

The `resources/security/workload_identity.cue` file and the `resources/security` package SHALL be removed entirely. No `#WorkloadIdentityResource` definition SHALL exist.

#### Scenario: Resource package does not exist

- **WHEN** the `resources/security/` directory is inspected
- **THEN** it SHALL NOT exist

#### Scenario: Resource import path is invalid

- **WHEN** CUE code attempts to import `opmodel.dev/resources/security@v0`
- **THEN** the import SHALL fail because the package no longer exists

## REMOVED Requirements

### Requirement: WorkloadIdentity resource definition exists

**Reason**: WorkloadIdentity is reclassified from Resource to Trait. The `#WorkloadIdentityResource` definition wrapping `core.#Resource` is replaced by `#WorkloadIdentityTrait` wrapping `core.#Trait`.

**Migration**: Replace `security_resources.#WorkloadIdentityResource` with `security_traits.#WorkloadIdentityTrait`. Replace `security_resources.#WorkloadIdentity` component mixin with `security_traits.#WorkloadIdentity`. The import path changes from `opmodel.dev/resources/security@v0` to `opmodel.dev/traits/security@v0`.

### Requirement: WorkloadIdentity component mixin exists

**Reason**: The mixin moves from `#resources` registration to `#traits` registration as part of the Resource-to-Trait reclassification.

**Migration**: Replace `security_resources.#WorkloadIdentity` with `security_traits.#WorkloadIdentity` in component definitions. The mixin now registers into `#traits` instead of `#resources`.
