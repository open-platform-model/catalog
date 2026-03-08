## ADDED Requirements

### Requirement: Declarative match plan in CUE

The catalog SHALL define `#MatchPlan` in `v1alpha1/core/matcher/` that takes `#provider` (a `#Provider`) and `#components` (a component map) as inputs, and computes a full component-to-transformer match matrix. For each (component, transformer) pair, it SHALL evaluate whether all required labels, required resources, and required traits are present on the component.

#### Scenario: Component matches a transformer
- **WHEN** a component has all required labels, resources, and traits for a transformer
- **THEN** the match result for that pair SHALL have `matched: true` and empty missing lists

#### Scenario: Component missing required label
- **WHEN** a component lacks a label required by a transformer
- **THEN** the match result for that pair SHALL have `matched: false` and `missingLabels` SHALL contain the missing label key

#### Scenario: Component missing required resource
- **WHEN** a component does not declare a resource FQN required by a transformer
- **THEN** the match result SHALL have `matched: false` and `missingResources` SHALL contain the missing FQN

#### Scenario: Component missing required trait
- **WHEN** a component does not declare a trait FQN required by a transformer
- **THEN** the match result SHALL have `matched: false` and `missingTraits` SHALL contain the missing FQN

### Requirement: MatchResult captures match outcome

`#MatchResult` SHALL contain `matched: bool`, `missingLabels: [...string]`, `missingResources: [...string]`, and `missingTraits: [...string]`. A result is matched only when all three missing lists are empty.

#### Scenario: Fully matched result
- **WHEN** a component satisfies all requirements of a transformer
- **THEN** `matched` SHALL be `true` and all missing lists SHALL be empty

### Requirement: Unmatched components are identified

`#MatchPlan` SHALL compute an `unmatched` list containing the names of components that matched zero transformers across the entire provider.

#### Scenario: Component with no matching transformer
- **WHEN** a component fails to match any transformer in the provider
- **THEN** its name SHALL appear in `#MatchPlan.unmatched`

### Requirement: Unhandled traits are detected

`#MatchPlan` SHALL compute `unhandledTraits` per component — the set of trait FQNs attached to a component that no matched transformer declares (neither required nor optional). This enables warning generation for traits that will be silently ignored.

#### Scenario: Trait not covered by any matched transformer
- **WHEN** a component has a trait and no matched transformer lists it as required or optional
- **THEN** that trait's FQN SHALL appear in `unhandledTraits` for that component

#### Scenario: Trait covered by at least one transformer
- **WHEN** a component has a trait and at least one matched transformer lists it
- **THEN** that trait SHALL NOT appear in `unhandledTraits`
