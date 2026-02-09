## ADDED Requirements

### Requirement: Plural resources carry a list-output annotation

Plural resources (resources whose `#spec` defines a map of entries) SHALL include the annotation `transformer.opmodel.dev/list-output: true` in their `metadata.annotations`.

#### Scenario: VolumesResource has the annotation

- **WHEN** `#VolumesResource` is defined
- **THEN** `#VolumesResource.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

#### Scenario: Singular resources do not have the annotation

- **WHEN** `#ContainerResource`, `#ConfigMapResource`, `#SecretResource`, or `#WorkloadIdentityResource` is defined
- **THEN** their `metadata.annotations` SHALL NOT include `transformer.opmodel.dev/list-output`

#### Scenario: Future plural resource carries the annotation

- **WHEN** a new resource definition uses a map pattern in its `#spec`
- **THEN** it SHALL include `"transformer.opmodel.dev/list-output": true` in its `metadata.annotations`

### Requirement: Annotation propagates to component via existing inheritance

The `transformer.opmodel.dev/list-output` annotation SHALL propagate from resources to the component through the existing annotation inheritance mechanism on `#Component`. No changes to `#Component` are required.

#### Scenario: Component with Volumes resource inherits the annotation

- **WHEN** a component includes `#VolumesResource` in its `#resources`
- **THEN** `component.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

#### Scenario: Component without plural resources has no list-output annotation

- **WHEN** a component includes only singular resources
- **THEN** `component.metadata.annotations` SHALL NOT contain `transformer.opmodel.dev/list-output`

#### Scenario: Component with both singular and plural resources

- **WHEN** a component includes both `#ContainerResource` and `#VolumesResource`
- **THEN** `component.metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

### Requirement: Consumers treat absence as single output

Downstream consumers SHALL treat the absence of the `transformer.opmodel.dev/list-output` annotation as indicating single-object output. Only an explicit `true` value SHALL indicate map output.

#### Scenario: Consumer reads component with annotation present

- **WHEN** a consumer reads a component where `metadata.annotations["transformer.opmodel.dev/list-output"]` is `true`
- **THEN** the consumer SHALL treat transformer output for that component as a keyed map of resources

#### Scenario: Consumer reads component with annotation absent

- **WHEN** a consumer reads a component where `metadata.annotations` does not contain `transformer.opmodel.dev/list-output`
- **THEN** the consumer SHALL treat transformer output for that component as a single resource object
