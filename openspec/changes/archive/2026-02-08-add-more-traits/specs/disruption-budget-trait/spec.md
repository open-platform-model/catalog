## ADDED Requirements

### Requirement: DisruptionBudget schema definition

The schemas module SHALL define a `#DisruptionBudgetSchema` that specifies availability constraints during voluntary disruptions. The schema SHALL include optional fields `minAvailable` and `maxUnavailable`, each accepting either an int or a percentage string (e.g., `"50%"`). At least one of `minAvailable` or `maxUnavailable` MUST be specified. Both fields SHALL NOT be set simultaneously.

#### Scenario: Schema validates minAvailable as integer

- **WHEN** a component specifies `disruptionBudget: { minAvailable: 2 }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates maxUnavailable as percentage

- **WHEN** a component specifies `disruptionBudget: { maxUnavailable: "25%" }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema rejects both fields set

- **WHEN** a component specifies `disruptionBudget: { minAvailable: 2, maxUnavailable: 1 }`
- **THEN** the schema SHALL reject the value because only one of `minAvailable` or `maxUnavailable` MAY be set

#### Scenario: Schema rejects empty disruption budget

- **WHEN** a component specifies `disruptionBudget: {}`
- **THEN** the schema SHALL reject the value because at least one field MUST be specified

### Requirement: DisruptionBudget trait definition

The traits module SHALL define a `#DisruptionBudgetTrait` in `traits/workload/disruption_budget.cue` that wraps `#DisruptionBudgetSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `maxUnavailable: 1` as a sensible starting point.

#### Scenario: Trait composes with a stateless workload

- **WHEN** a component includes `#Container` resource and `#DisruptionBudget` trait
- **THEN** the component SHALL validate successfully and expose `spec.disruptionBudget` in its spec

#### Scenario: Trait is meaningful only with replicated workloads

- **WHEN** a component includes `#DisruptionBudget` without a replication trait
- **THEN** the trait SHALL still validate at the definition level (semantic enforcement is a transformer concern)
