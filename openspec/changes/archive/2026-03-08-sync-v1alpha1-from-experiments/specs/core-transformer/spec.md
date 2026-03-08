## MODIFIED Requirements

### Requirement: TransformerContext namespace and label changes

In the CUE catalog, `#TransformerContext` in `v1alpha1/core/transformer/transformer.cue` SHALL no longer carry flat `name` and `namespace` fields. Namespace SHALL be accessed via `#context.#moduleReleaseMetadata.namespace`. A new `module-release.opmodel.dev/name` label SHALL be injected into `componentLabels`, set to `#moduleReleaseMetadata.name`.

#### Scenario: TransformerContext namespace access
- **WHEN** a transformer reads the target namespace from `#TransformerContext`
- **THEN** it SHALL access it via `#context.#moduleReleaseMetadata.namespace`
- **AND** no flat `namespace` field SHALL exist on `#TransformerContext`

#### Scenario: TransformerContext has no flat name field
- **WHEN** `#TransformerContext` is evaluated
- **THEN** no flat `name` field SHALL exist at the top level of the context

#### Scenario: Module release name label in componentLabels
- **WHEN** `#TransformerContext` computes `componentLabels`
- **THEN** the labels SHALL include `module-release.opmodel.dev/name` set to `#moduleReleaseMetadata.name`
