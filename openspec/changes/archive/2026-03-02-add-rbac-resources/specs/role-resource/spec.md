## ADDED Requirements

### Requirement: PolicyRule schema exists

The system SHALL provide a `#PolicyRuleSchema` definition in `schemas/security.cue` defining a single RBAC permission rule with required `apiGroups`, `resources`, and `verbs` fields.

#### Scenario: Schema structure

- **WHEN** `#PolicyRuleSchema` is evaluated
- **THEN** it SHALL require `apiGroups!: [...string]`, `resources!: [...string]`, and `verbs!: [...string]`

#### Scenario: Missing required fields rejected

- **WHEN** a PolicyRule spec omits `verbs`
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: Valid rule accepted

- **WHEN** a PolicyRule specifies `apiGroups: [""], resources: ["pods"], verbs: ["get", "list", "watch"]`
- **THEN** CUE validation SHALL accept it

### Requirement: RoleSubject schema exists

The system SHALL provide a `#RoleSubjectSchema` definition in `schemas/security.cue` that embeds a `#WorkloadIdentitySchema` or `#ServiceAccountSchema` disjunction directly (no wrapper field).

#### Scenario: Schema accepts embedded WorkloadIdentity

- **WHEN** a RoleSubject embeds a `#WorkloadIdentitySchema` value with `name: "my-app"`
- **THEN** CUE validation SHALL accept it and the subject's `name` SHALL resolve to `"my-app"`

#### Scenario: Schema accepts embedded ServiceAccount

- **WHEN** a RoleSubject embeds a `#ServiceAccountSchema` value with `name: "ci-bot"`
- **THEN** CUE validation SHALL accept it and the subject's `name` SHALL resolve to `"ci-bot"`

#### Scenario: Schema rejects non-identity value

- **WHEN** a RoleSubject contains fields that satisfy neither `#WorkloadIdentitySchema` nor `#ServiceAccountSchema`
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: Role schema exists

The system SHALL provide a `#RoleSchema` definition in `schemas/security.cue` with required `name`, `rules`, and `subjects` fields, and a `scope` field defaulting to `"namespace"`.

#### Scenario: Schema structure

- **WHEN** `#RoleSchema` is evaluated
- **THEN** it SHALL require `name!: string`, `rules!: [...#PolicyRuleSchema]`, and `subjects!: [...#RoleSubjectSchema]`, and provide `scope: *"namespace" | "cluster"`

#### Scenario: Namespace scope is default

- **WHEN** a Role spec omits the `scope` field
- **THEN** `scope` SHALL default to `"namespace"`

#### Scenario: Cluster scope accepted

- **WHEN** a Role spec sets `scope: "cluster"`
- **THEN** CUE validation SHALL accept it

#### Scenario: Invalid scope rejected

- **WHEN** a Role spec sets `scope: "global"`
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: At least one rule required

- **WHEN** a Role spec provides `rules: []` (empty list)
- **THEN** CUE validation SHALL reject it at definition time

#### Scenario: At least one subject required

- **WHEN** a Role spec provides `subjects: []` (empty list)
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: Role resource definition exists

The system SHALL provide a `#RoleResource` definition in `resources/security/role.cue` that wraps `#RoleSchema` using the `core.#Resource` pattern.

#### Scenario: Resource definition structure

- **WHEN** `#RoleResource` is evaluated
- **THEN** it SHALL satisfy `core.#Resource` with `modulePath: "opmodel.dev/resources/security"`, `name: "role"`, and `spec: close({role: schemas.#RoleSchema})`

#### Scenario: Resource definition is closed

- **WHEN** a field not in `#RoleSchema` is added to a Role spec
- **THEN** CUE validation SHALL reject it at definition time

### Requirement: Role component mixin exists

The system SHALL provide a `#Role` component mixin that adds the Role resource FQN to a component's `#resources` map.

#### Scenario: Mixin adds resource to component

- **WHEN** a component embeds `security_resources.#Role`
- **THEN** the component's `#resources` map SHALL contain the key matching `#RoleResource.metadata.fqn` with value `#RoleResource`

#### Scenario: Mixin composes with ServiceAccount resource

- **WHEN** a component embeds both `security_resources.#ServiceAccount` and `security_resources.#Role`
- **THEN** both resource FQNs SHALL be present in `#resources` without conflict

### Requirement: Role defaults exist

The system SHALL provide a `#RoleDefaults` definition that satisfies `#RoleSchema`.

#### Scenario: Default scope is namespace

- **WHEN** `#RoleDefaults` is evaluated
- **THEN** `scope` SHALL be `"namespace"`

### Requirement: Role is provider-agnostic

The `#RoleSchema` SHALL NOT contain any provider-specific fields. It expresses the intent of granting permissions to identities, not how those permissions are realized.

#### Scenario: No K8s-specific fields

- **WHEN** `#RoleSchema` is inspected
- **THEN** it SHALL NOT contain fields like `roleRef`, `clusterRole`, `bindingName`, or any other provider-specific concept
