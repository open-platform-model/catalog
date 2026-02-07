## ADDED Requirements

### Requirement: PolicyRule primitive type

The core module SHALL define a `#PolicyRule` type that encodes governance rules, security requirements, compliance controls, and operational guardrails. `#PolicyRule` replaces the former `#Policy` primitive.

#### Scenario: Valid PolicyRule definition

- **WHEN** a CUE definition extends `#PolicyRule` with all required fields (`metadata.apiVersion`, `metadata.name`, `enforcement.mode`, `enforcement.onViolation`, `#spec`)
- **THEN** CUE validation SHALL pass

#### Scenario: PolicyRule kind field

- **WHEN** a `#PolicyRule` is defined
- **THEN** the `kind` field SHALL be `"PolicyRule"`

#### Scenario: PolicyRule apiVersion field

- **WHEN** a `#PolicyRule` is defined
- **THEN** the top-level `apiVersion` field SHALL be `"opmodel.dev/core/v0"`

### Requirement: PolicyRule metadata

The `#PolicyRule` metadata SHALL include `apiVersion`, `name`, computed `fqn`, and optional `description`, `labels`, `annotations`. The `target` field SHALL NOT exist.

#### Scenario: FQN computation

- **WHEN** a `#PolicyRule` has `metadata.apiVersion: "opmodel.dev/policies/connectivity@v0"` and `metadata.name: "network-rules"`
- **THEN** `metadata.fqn` SHALL be `"opmodel.dev/policies/connectivity@v0#NetworkRules"`

#### Scenario: No target field

- **WHEN** a `#PolicyRule` is defined with a `metadata.target` field
- **THEN** CUE validation SHALL fail (field not allowed)

### Requirement: PolicyRule enforcement

The `#PolicyRule` SHALL require an `enforcement` block with `mode` and `onViolation` fields.

#### Scenario: Valid enforcement modes

- **WHEN** `enforcement.mode` is set to `"deployment"`, `"runtime"`, or `"both"`
- **THEN** CUE validation SHALL pass

#### Scenario: Invalid enforcement mode

- **WHEN** `enforcement.mode` is set to any value other than `"deployment"`, `"runtime"`, or `"both"`
- **THEN** CUE validation SHALL fail

#### Scenario: Valid violation actions

- **WHEN** `enforcement.onViolation` is set to `"block"`, `"warn"`, or `"audit"`
- **THEN** CUE validation SHALL pass

#### Scenario: Optional platform enforcement

- **WHEN** `enforcement.platform` is provided with any structure
- **THEN** CUE validation SHALL pass (field is open)

### Requirement: PolicyRule spec auto-naming

The `#spec` field SHALL automatically derive its top-level key from the camelCase form of the definition name.

#### Scenario: Spec key derivation

- **WHEN** a `#PolicyRule` has `metadata.name: "network-rules"`
- **THEN** the `#spec` top-level key SHALL be `networkRules`

### Requirement: PolicyRule file location

The `#PolicyRule` definition SHALL be in `v0/core/policy_rule.cue`.

#### Scenario: File exists at correct path

- **WHEN** the core module is loaded
- **THEN** `v0/core/policy_rule.cue` SHALL contain the `#PolicyRule` definition

### Requirement: PolicyRuleMap type alias

A `#PolicyRuleMap` type alias SHALL be defined as `[string]: _`.

#### Scenario: Map type usage

- **WHEN** `#PolicyRuleMap` is referenced
- **THEN** it SHALL accept a map of string keys to any value

### Requirement: Downstream concrete names unchanged

Concrete PolicyRule instances in `v0/policies/` SHALL keep their existing names. Only the core type they extend SHALL change.

#### Scenario: NetworkRulesPolicy name preserved

- **WHEN** `#NetworkRulesPolicy` is defined in `v0/policies/network/network_rules.cue`
- **THEN** it SHALL extend `core.#PolicyRule` (not `core.#Policy`)
- **THEN** the definition name SHALL remain `#NetworkRulesPolicy`

#### Scenario: SharedNetworkPolicy name preserved

- **WHEN** `#SharedNetworkPolicy` is defined in `v0/policies/network/shared_network.cue`
- **THEN** it SHALL extend `core.#PolicyRule` (not `core.#Policy`)
- **THEN** the definition name SHALL remain `#SharedNetworkPolicy`

## REMOVED Requirements

### Requirement: Policy primitive type

**Reason**: Renamed to `#PolicyRule` to free the `#Policy` name for the construct (formerly `#Scope`).
**Migration**: Replace `core.#Policy` with `core.#PolicyRule` in all PolicyRule definitions.

### Requirement: metadata.target field

**Reason**: Only valid value was `"scope"`. Single-value fields provide no discrimination.
**Migration**: Remove `target` from PolicyRule metadata. No replacement needed.
