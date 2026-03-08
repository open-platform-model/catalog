## ADDED Requirements

### Requirement: CUE-side match plan coexists with Go-side matching

The catalog SHALL provide a `#MatchPlan` in `v1alpha1/core/matcher/` that performs the same matching logic as the CLI's Go-side implementation. Both implementations SHALL produce equivalent results for the same inputs. The CUE-side matcher enables CUE-native validation and tooling without requiring the Go CLI.

#### Scenario: CUE matcher agrees with Go matcher
- **WHEN** the same components and provider transformers are evaluated by both `#MatchPlan` (CUE) and `TransformerMatchPlan` (Go CLI)
- **THEN** the set of matched transformers per component SHALL be identical

#### Scenario: CUE matcher is self-contained
- **WHEN** `#MatchPlan` is evaluated with a `#Provider` and component map
- **THEN** it SHALL produce complete match results without requiring any Go-side evaluation
