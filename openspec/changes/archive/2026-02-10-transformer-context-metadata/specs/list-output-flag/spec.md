## MODIFIED Requirements

### Requirement: Annotation propagates to component via existing inheritance

The `transformer.opmodel.dev/list-output` annotation SHALL propagate from resources to the component through the existing annotation inheritance mechanism on `#Component`. No changes to `#Component` are required. However, `#TransformerContext` SHALL filter this annotation from `componentAnnotations` so it does not appear on rendered provider resources.

#### Scenario: Component with Volumes resource inherits the annotation

- **WHEN** a component includes `#VolumesResource` in its `#resources`
- **THEN** `component.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

#### Scenario: Component without plural resources has no list-output annotation

- **WHEN** a component includes only singular resources
- **THEN** `component.metadata.annotations` SHALL NOT contain `transformer.opmodel.dev/list-output`

#### Scenario: Component with both singular and plural resources

- **WHEN** a component includes both `#ContainerResource` and `#VolumesResource`
- **THEN** `component.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

#### Scenario: Annotation is stripped from TransformerContext componentAnnotations

- **WHEN** a component has `metadata.annotations["transformer.opmodel.dev/list-output"]: true`
- **AND** a `#TransformerContext` is constructed with that component's metadata
- **THEN** `componentAnnotations` SHALL NOT contain the key `transformer.opmodel.dev/list-output`

#### Scenario: Annotation remains accessible on component metadata for pipeline use

- **WHEN** a transformer receives `#component` with `metadata.annotations["transformer.opmodel.dev/list-output"]: true`
- **THEN** the transformer MAY read `#component.metadata.annotations["transformer.opmodel.dev/list-output"]` directly for pipeline logic
- **AND** this value SHALL still be `true`
