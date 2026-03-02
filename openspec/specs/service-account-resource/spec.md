## Purpose

Defines the standalone ServiceAccount resource for OPM, providing a named identity independent of any workload or the WorkloadIdentity trait.

## Requirements

### Requirement: ServiceAccount schema exists

The system SHALL provide a `#ServiceAccountSchema` definition in `schemas/security.cue` with a required `name` field and an optional `automountToken` field.

#### Scenario: Schema structure

- **WHEN** `#ServiceAccountSchema` is evaluated
- **THEN** it SHALL require `name!: string` and provide `automountToken?: bool`

#### Scenario: Missing name rejected

- **WHEN** a ServiceAccount spec omits the `name` field
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: automountToken is optional

- **WHEN** a ServiceAccount spec provides only `name: "ci-bot"`
- **THEN** CUE validation SHALL accept it without requiring `automountToken`

### Requirement: ServiceAccount resource definition exists

The system SHALL provide a `#ServiceAccountResource` definition in `resources/security/service_account.cue` that wraps `#ServiceAccountSchema` using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#ServiceAccountResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `modulePath: "opmodel.dev/resources/security"`, `name: "service-account"`, and `spec: close({serviceAccount: schemas.#ServiceAccountSchema})`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#ServiceAccountSchema` is added to a ServiceAccount spec
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: ServiceAccount component mixin exists

The system SHALL provide a `#ServiceAccount` component mixin that adds the ServiceAccount resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `security_resources.#ServiceAccount`
- **THEN** the component's `#resources` map SHALL contain the key matching `#ServiceAccountResource.metadata.fqn` with value `#ServiceAccountResource`

#### Scenario: Mixin composes with other resources

- **WHEN** a component embeds both `config_resources.#Secrets` and `security_resources.#ServiceAccount`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

### Requirement: ServiceAccount defaults exist

The system SHALL provide a `#ServiceAccountDefaults` definition that satisfies `#ServiceAccountSchema`.

#### Scenario: Defaults are valid

- **WHEN** `#ServiceAccountDefaults` is evaluated
- **THEN** it SHALL unify with `#ServiceAccountSchema` without error and `automountToken` SHALL default to `false`

### Requirement: ServiceAccount is provider-agnostic

The `#ServiceAccountSchema` SHALL NOT contain any provider-specific fields. It expresses the intent of having a named identity, not how that identity is realized.

#### Scenario: No K8s-specific fields

- **WHEN** `#ServiceAccountSchema` is inspected
- **THEN** it SHALL NOT contain fields like `serviceAccountName`, `iamRole`, `annotations`, or any other provider-specific concept
