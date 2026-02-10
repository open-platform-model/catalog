## ADDED Requirements

### Requirement: TransformerContext filters transformer.opmodel.dev labels from component output

`#TransformerContext.componentLabels` SHALL exclude any labels whose key starts with the prefix `transformer.opmodel.dev/`. These labels remain on `#Component.metadata.labels` for matching purposes but SHALL NOT propagate to rendered provider resources.

#### Scenario: Component with transformer-prefixed label

- **WHEN** a component has `metadata.labels["transformer.opmodel.dev/some-flag"]: "true"`
- **AND** a `#TransformerContext` is constructed with that component's metadata
- **THEN** `componentLabels` SHALL NOT contain the key `transformer.opmodel.dev/some-flag`
- **AND** the merged `labels` field SHALL NOT contain the key `transformer.opmodel.dev/some-flag`

#### Scenario: Component with non-transformer-prefixed labels preserved

- **WHEN** a component has `metadata.labels["core.opmodel.dev/workload-type"]: "stateless"`
- **AND** a `#TransformerContext` is constructed with that component's metadata
- **THEN** `componentLabels` SHALL contain `core.opmodel.dev/workload-type: "stateless"`

#### Scenario: Transformer matching still sees filtered labels

- **WHEN** a transformer defines `requiredLabels: {"transformer.opmodel.dev/some-flag": "true"}`
- **AND** a component has `metadata.labels["transformer.opmodel.dev/some-flag"]: "true"`
- **THEN** `#Matches` SHALL evaluate to `true` (matching uses `component.metadata.labels` directly, not `componentLabels`)

#### Scenario: Mixed labels on component

- **WHEN** a component has labels `{"core.opmodel.dev/workload-type": "stateless", "transformer.opmodel.dev/list-output": "true", "app.example.com/team": "platform"}`
- **AND** a `#TransformerContext` is constructed with that component's metadata
- **THEN** `componentLabels` SHALL contain `core.opmodel.dev/workload-type` and `app.example.com/team`
- **AND** `componentLabels` SHALL NOT contain `transformer.opmodel.dev/list-output`

### Requirement: TransformerContext filters transformer.opmodel.dev annotations from component output

`#TransformerContext.componentAnnotations` SHALL exclude any annotations whose key starts with the prefix `transformer.opmodel.dev/`. These annotations remain on `#Component.metadata.annotations` for pipeline use but SHALL NOT propagate to rendered provider resources.

#### Scenario: Component with transformer-prefixed annotation

- **WHEN** a component has `metadata.annotations["transformer.opmodel.dev/list-output"]: true`
- **AND** a `#TransformerContext` is constructed with that component's metadata
- **THEN** `componentAnnotations` SHALL NOT contain the key `transformer.opmodel.dev/list-output`

#### Scenario: Non-transformer annotations preserved

- **WHEN** a component has `metadata.annotations["app.example.com/owner"]: "team-a"`
- **AND** a `#TransformerContext` is constructed with that component's metadata
- **THEN** `componentAnnotations` SHALL contain `app.example.com/owner: "team-a"`

### Requirement: TransformerContext metadata fields are typed

`#TransformerContext` SHALL type its metadata fields against the actual definition schemas rather than using unconstrained (`_`) types.

#### Scenario: moduleReleaseMetadata is typed as ModuleRelease.metadata

- **WHEN** `#TransformerContext` is defined
- **THEN** `#moduleReleaseMetadata` SHALL be typed as `#ModuleRelease.metadata`
- **AND** providing a value that does not satisfy `#ModuleRelease.metadata` SHALL cause a CUE evaluation error

#### Scenario: componentMetadata is typed as Component.metadata

- **WHEN** `#TransformerContext` is defined
- **THEN** `#componentMetadata` SHALL be typed as `#Component.metadata`
- **AND** providing a value that does not satisfy `#Component.metadata` SHALL cause a CUE evaluation error

#### Scenario: Untyped metadata rejected

- **WHEN** a `#TransformerContext` is constructed with `#moduleReleaseMetadata: {name: "test", version: "0.1.0"}` (missing required fields like `namespace`)
- **THEN** CUE evaluation SHALL fail
