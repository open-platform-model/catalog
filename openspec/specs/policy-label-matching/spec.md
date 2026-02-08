## Requirements

### Requirement: appliesTo with matchLabels

The `#Policy.appliesTo` block SHALL support a `matchLabels` field for label-based component selection, in addition to the existing explicit `components` reference.

#### Scenario: matchLabels selects components by label equality

- **WHEN** a `#Policy` has `appliesTo.matchLabels: { "core.opmodel.dev/workload-type": "stateless" }`
- **THEN** the policy SHALL apply to all components in the module whose `metadata.labels` contain `"core.opmodel.dev/workload-type": "stateless"`

#### Scenario: matchLabels requires all labels to match

- **WHEN** `matchLabels` specifies multiple key-value pairs
- **THEN** a component SHALL only match if its labels contain ALL specified key-value pairs (AND semantics)

#### Scenario: matchLabels is optional

- **WHEN** `appliesTo` omits `matchLabels`
- **THEN** CUE validation SHALL pass

### Requirement: appliesTo with explicit components

The `#Policy.appliesTo` block SHALL support a `components` field for explicit component references using full `#Component` structs.

#### Scenario: Explicit component reference

- **WHEN** a `#Policy` has `appliesTo.components: [#components["api-server"]]`
- **THEN** the policy SHALL apply to the referenced component

#### Scenario: components is optional

- **WHEN** `appliesTo` omits `components`
- **THEN** CUE validation SHALL pass

### Requirement: appliesTo OR semantics

When both `matchLabels` and `components` are provided, they SHALL use OR semantics — a component matches if it satisfies either condition.

#### Scenario: Component matches via labels only

- **WHEN** a component's labels satisfy `matchLabels` but the component is not in `components`
- **THEN** the policy SHALL apply to that component

#### Scenario: Component matches via explicit reference only

- **WHEN** a component is listed in `components` but its labels do not satisfy `matchLabels`
- **THEN** the policy SHALL apply to that component

#### Scenario: Component matches via both

- **WHEN** a component satisfies both `matchLabels` and is listed in `components`
- **THEN** the policy SHALL apply to that component (no duplication)

### Requirement: appliesTo replaces componentLabels

The former `componentLabels` field SHALL NOT exist on `#Policy.appliesTo`. `matchLabels` replaces it with a clearer, flatter structure.

#### Scenario: componentLabels field rejected

- **WHEN** a `#Policy` defines `appliesTo.componentLabels`
- **THEN** CUE validation SHALL fail (field not allowed in closed struct)
