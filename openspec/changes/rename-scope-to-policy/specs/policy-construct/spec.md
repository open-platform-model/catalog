## ADDED Requirements

### Requirement: Policy construct type

The core module SHALL define a `#Policy` construct that groups `#PolicyRule` primitives and targets them to components. `#Policy` replaces the former `#Scope` construct.

#### Scenario: Valid Policy definition

- **WHEN** a CUE definition extends `#Policy` with `metadata.name`, at least one rule in `#rules`, and an `appliesTo` block
- **THEN** CUE validation SHALL pass

#### Scenario: Policy kind field

- **WHEN** a `#Policy` is defined
- **THEN** the `kind` field SHALL be `"Policy"`

#### Scenario: Policy apiVersion field

- **WHEN** a `#Policy` is defined
- **THEN** the top-level `apiVersion` field SHALL be `"opmodel.dev/core/v0"`

### Requirement: Policy metadata

The `#Policy` metadata SHALL include required `name` and optional `labels`, `annotations`.

#### Scenario: Name validation

- **WHEN** `metadata.name` is a valid `#NameType` (kebab-case)
- **THEN** CUE validation SHALL pass

### Requirement: Policy rules field

The `#Policy` SHALL contain a `#rules` field that is a map of `#PolicyRule` instances keyed by FQN string.

#### Scenario: Single rule

- **WHEN** a `#Policy` has one entry in `#rules` keyed by a PolicyRule FQN
- **THEN** CUE validation SHALL pass and the rule's `#spec` fields SHALL unify into `spec`

#### Scenario: Multiple rules

- **WHEN** a `#Policy` has multiple entries in `#rules` with non-conflicting `#spec` fields
- **THEN** CUE validation SHALL pass and all rules' `#spec` fields SHALL unify into `spec`

#### Scenario: Conflicting rule specs

- **WHEN** two `#PolicyRule` instances in `#rules` define the same `#spec` key with incompatible types
- **THEN** CUE unification SHALL fail at definition time

### Requirement: Policy spec unification

The `#Policy` SHALL automatically unify all `#spec` fields from its `#rules` into a closed `spec` field.

#### Scenario: Spec contains all rule fields

- **WHEN** a `#Policy` has rules with `#spec` keys `networkRules` and `sharedNetwork`
- **THEN** `spec` SHALL contain both `networkRules` and `sharedNetwork`

#### Scenario: Spec is closed

- **WHEN** a user adds a field to `spec` that does not come from any rule's `#spec`
- **THEN** CUE validation SHALL fail

### Requirement: Policy on Module

The `#Module` definition SHALL have an optional `#policies` field that is a map of `#Policy` instances.

#### Scenario: Module with policies

- **WHEN** a `#Module` defines `#policies: { "network": #Policy & {...} }`
- **THEN** CUE validation SHALL pass

#### Scenario: Module without policies

- **WHEN** a `#Module` omits the `#policies` field
- **THEN** CUE validation SHALL pass (field is optional)

### Requirement: Policy on ModuleRelease

The `#ModuleRelease` definition SHALL have an optional `policies` field that mirrors the module's `#policies`.

#### Scenario: ModuleRelease inherits policies

- **WHEN** a `#ModuleRelease` references a `#Module` that has `#policies`
- **THEN** `#ModuleRelease.policies` SHALL contain the module's policies

### Requirement: Policy file location

The `#Policy` construct SHALL be in `v0/core/policy.cue`.

#### Scenario: File exists at correct path

- **WHEN** the core module is loaded
- **THEN** `v0/core/policy.cue` SHALL contain the `#Policy` definition

### Requirement: PolicyMap type alias

A `#PolicyMap` type alias SHALL be defined as `[string]: #Policy`.

#### Scenario: Map type usage

- **WHEN** `#PolicyMap` is referenced
- **THEN** it SHALL accept a map of string keys to `#Policy` values

### Requirement: Pre-built Policy constructs

The `v0/policies/` module SHALL provide pre-built `#Policy` constructs with rules pre-loaded. These serve as ready-to-use templates that users compose into their modules.

#### Scenario: NetworkRules pre-built construct

- **WHEN** `#NetworkRules` is defined in `v0/policies/network/network_rules.cue`
- **THEN** it SHALL extend `core.#Policy` (not `core.#Scope`)
- **THEN** it SHALL have `#NetworkRulesPolicy` pre-loaded in `#rules`

#### Scenario: SharedNetwork pre-built construct

- **WHEN** `#SharedNetwork` is defined in `v0/policies/network/shared_network.cue`
- **THEN** it SHALL extend `core.#Policy` (not `core.#Scope`)
- **THEN** it SHALL have `#SharedNetworkPolicy` pre-loaded in `#rules`

#### Scenario: Users compose pre-built constructs via CUE unification

- **WHEN** a module author writes `#policies: { "net": network.#NetworkRules & network.#SharedNetwork & { appliesTo: {...} } }`
- **THEN** CUE unification SHALL unify both constructs' rules and specs into a single `#Policy`

## REMOVED Requirements

### Requirement: Scope construct type

**Reason**: Renamed to `#Policy` to align with KubeVela's learned terminology.
**Migration**: Replace `core.#Scope` with `core.#Policy`. Replace `#scopes` with `#policies` on Module and ModuleRelease.

### Requirement: ScopeMap type alias

**Reason**: Replaced by `#PolicyMap`.
**Migration**: Replace `#ScopeMap` with `#PolicyMap`.

## RENAMED Requirements

### Requirement: Scope internal policies field → rules

- **FROM**: `#Scope.#policies`
- **TO**: `#Policy.#rules`
