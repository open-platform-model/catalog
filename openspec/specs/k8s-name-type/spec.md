# Capability: k8s-name-type

## Purpose

Enforce Kubernetes-compatible naming across all OPM core definitions by constraining `#NameType` to RFC 1123 DNS labels, introducing `#APIVersionType` for apiVersion fields, and providing a `#KebabToPascal` conversion function for FQN compatibility.

## Requirements

### Requirement: NameType enforces RFC 1123 DNS label format

`#NameType` SHALL be redefined as a string constrained to the Kubernetes DNS label standard (RFC 1123 label): lowercase alphanumeric characters and hyphens, starting and ending with an alphanumeric character, with a maximum length of 63 characters and a minimum length of 1 character.

The regex pattern SHALL be: `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`

The previous definition (`string & strings.MinRunes(1) & strings.MaxRunes(254)`) SHALL be replaced entirely.

#### Scenario: Valid DNS label name accepted

- **WHEN** a value matching `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` with length 1-63 is assigned to a `#NameType` field
- **THEN** CUE validation SHALL pass

#### Scenario: PascalCase name rejected

- **WHEN** a value like `"StatelessWorkload"` containing uppercase characters is assigned to a `#NameType` field
- **THEN** CUE validation SHALL fail at definition time

#### Scenario: Name with dots or slashes rejected

- **WHEN** a value like `"opmodel.dev/core@v0"` containing dots, slashes, or `@` is assigned to a `#NameType` field
- **THEN** CUE validation SHALL fail at definition time

#### Scenario: Name exceeding 63 characters rejected

- **WHEN** a string longer than 63 characters is assigned to a `#NameType` field
- **THEN** CUE validation SHALL fail at definition time

#### Scenario: Name starting or ending with hyphen rejected

- **WHEN** a value like `"-my-name"` or `"my-name-"` is assigned to a `#NameType` field
- **THEN** CUE validation SHALL fail at definition time

#### Scenario: Single character name accepted

- **WHEN** a single lowercase alphanumeric character like `"a"` or `"1"` is assigned to a `#NameType` field
- **THEN** CUE validation SHALL pass

### Requirement: APIVersionType introduced for apiVersion fields

A new type `#APIVersionType` SHALL be introduced in `v0/core/common.cue` to constrain `apiVersion` fields. This type SHALL accept the OPM apiVersion format: a domain path with version suffix (e.g., `"opmodel.dev/resources/workload@v0"`).

The constraint SHALL accept strings matching the pattern used in `#FQNType` for the apiVersion segment: `^[a-z0-9.-]+(/[a-z0-9.-]+)*@v[0-9]+$` with a minimum length of 1 and maximum length of 254.

#### Scenario: Standard OPM apiVersion accepted

- **WHEN** a value like `"opmodel.dev/resources/workload@v0"` is assigned to an `#APIVersionType` field
- **THEN** CUE validation SHALL pass

#### Scenario: Core apiVersion accepted

- **WHEN** a value like `"opmodel.dev/core/v0"` is assigned to a top-level `apiVersion` field constrained to a constant
- **THEN** CUE validation SHALL pass (top-level apiVersion fields use constant constraints, not `#APIVersionType`)

#### Scenario: Plain string without version rejected

- **WHEN** a value like `"opmodel.dev/resources"` without the `@v<N>` suffix is assigned to an `#APIVersionType` field
- **THEN** CUE validation SHALL fail at definition time

### Requirement: All metadata apiVersion fields use APIVersionType

Every `metadata.apiVersion!` field across all core definitions (`#Module`, `#Transformer`, `#Trait`, `#Template`, `#Resource`, `#Policy`, `#Bundle`, `#Blueprint`) SHALL be typed as `#APIVersionType` instead of `#NameType`.

Top-level `apiVersion` fields that are constrained to constant values (e.g., `apiVersion: "opmodel.dev/core/v0"`) MAY remain as-is since the constant already provides sufficient validation.

#### Scenario: Module metadata apiVersion typed correctly

- **WHEN** inspecting `#Module.metadata.apiVersion!`
- **THEN** its type SHALL be `#APIVersionType`

#### Scenario: All eight core definitions updated

- **WHEN** inspecting `metadata.apiVersion!` on `#Module`, `#Transformer`, `#Trait`, `#Template`, `#Resource`, `#Policy`, `#Bundle`, and `#Blueprint`
- **THEN** all eight SHALL use `#APIVersionType`

### Requirement: Consistent NameType application across all definitions

All core definitions that have a `metadata.name` field SHALL type it as `#NameType`. This includes `#Component`, `#Scope`, `#ModuleRelease`, `#BundleRelease`, and `#Provider` which currently use bare `string`.

#### Scenario: Component name uses NameType

- **WHEN** inspecting `#Component.metadata.name!`
- **THEN** its type SHALL be `#NameType`

#### Scenario: ModuleRelease name uses NameType

- **WHEN** inspecting `#ModuleRelease.metadata.name!`
- **THEN** its type SHALL be `#NameType`

#### Scenario: Provider name uses NameType

- **WHEN** inspecting `#Provider.metadata.name`
- **THEN** its type SHALL be `#NameType`

### Requirement: KebabToPascal function defined using Function Pattern

A reusable `#KebabToPascal` function SHALL be defined in `v0/core/common.cue` using the Function Pattern (consistent with `#Matches` in `transformer.cue` and `#MatchTransformers` in `provider.cue`).

The function SHALL accept a kebab-case string as input (`"in"` field) and produce a PascalCase string as output (`out` field) by splitting on hyphens and capitalizing the first letter of each segment.

CUE's `strings` package has no built-in kebab→PascalCase function (`strings.ToTitle` and `strings.ToCamel` do not treat hyphens as word boundaries), so this custom function is necessary.

#### Scenario: Single-word conversion

- **WHEN** `(#KebabToPascal & {"in": "container"}).out` is evaluated
- **THEN** the result SHALL be `"Container"`

#### Scenario: Multi-word conversion

- **WHEN** `(#KebabToPascal & {"in": "stateless-workload"}).out` is evaluated
- **THEN** the result SHALL be `"StatelessWorkload"`

#### Scenario: Acronym segments capitalize first letter only

- **WHEN** `(#KebabToPascal & {"in": "pvc-transformer"}).out` is evaluated
- **THEN** the result SHALL be `"PvcTransformer"` (not `"PVCTransformer"`)

#### Scenario: Single character conversion

- **WHEN** `(#KebabToPascal & {"in": "a"}).out` is evaluated
- **THEN** the result SHALL be `"A"`

### Requirement: Computed _definitionName field for FQN compatibility

A computed hidden field `_definitionName` SHALL be added to the `metadata` block of every core definition that has an `fqn` field. This field SHALL use `#KebabToPascal` to convert the kebab-case `name` to PascalCase:

`_definitionName: (#KebabToPascal & {"in": name}).out`

The `fqn` field SHALL interpolate `_definitionName` instead of `name`:

`fqn: #FQNType & "\(apiVersion)#\(_definitionName)"`

This ensures `#FQNType` continues to receive a PascalCase name segment without any changes to the FQN regex or format.

#### Scenario: FQN uses _definitionName via KebabToPascal

- **WHEN** a definition has `apiVersion: "opmodel.dev/resources/workload@v0"` and `name: "container"`
- **THEN** `_definitionName` SHALL be `"Container"` and `fqn` SHALL be `"opmodel.dev/resources/workload@v0#Container"`

#### Scenario: Multi-word name produces correct FQN

- **WHEN** a definition has `apiVersion: "opmodel.dev/blueprints/core@v0"` and `name: "stateless-workload"`
- **THEN** `_definitionName` SHALL be `"StatelessWorkload"` and `fqn` SHALL be `"opmodel.dev/blueprints/core@v0#StatelessWorkload"`

#### Scenario: _definitionName present on all FQN-bearing definitions

- **WHEN** inspecting `#Module`, `#Transformer`, `#Trait`, `#Template`, `#Resource`, `#Policy`, `#Bundle`, and `#Blueprint`
- **THEN** all eight SHALL have a computed `metadata._definitionName` field using `#KebabToPascal`

### Requirement: FQNType regex unchanged

`#FQNType` SHALL NOT be modified. The existing regex `^([a-z0-9.-]+(?:/[a-z0-9.-]+)*)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$` SHALL remain as-is, continuing to require PascalCase in the name segment.

#### Scenario: FQNType regex preserved

- **WHEN** inspecting `#FQNType` in `v0/core/common.cue`
- **THEN** the regex SHALL be `^([a-z0-9.-]+(?:/[a-z0-9.-]+)*)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$`

#### Scenario: PascalCase FQN still accepted

- **WHEN** a value like `"opmodel.dev/resources/workload@v0#Container"` is assigned to a `#FQNType` field
- **THEN** CUE validation SHALL pass

#### Scenario: Kebab-case FQN still rejected

- **WHEN** a value like `"opmodel.dev/resources/workload@v0#container"` is assigned to a `#FQNType` field
- **THEN** CUE validation SHALL fail

### Requirement: NameSchema synchronized or removed

`#NameSchema` in `v0/schemas/common.cue` SHALL either be updated to match the new `#NameType` constraint or removed entirely, since it is currently unused dead code. If retained, it MUST be kept in sync with `#NameType`.

#### Scenario: NameSchema matches NameType

- **WHEN** `#NameSchema` exists in `v0/schemas/common.cue`
- **THEN** its constraint SHALL be identical to `#NameType` in `v0/core/common.cue`

#### Scenario: NameSchema removed if unused

- **WHEN** no file in the codebase references `#NameSchema`
- **THEN** it MAY be removed from `v0/schemas/common.cue`
