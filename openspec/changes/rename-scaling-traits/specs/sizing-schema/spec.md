## ADDED Requirements

### Requirement: SizingSchema struct definition

The `#SizingSchema` SHALL be a CUE struct with optional `cpu`, `memory`, and `auto` fields, replacing `#ResourceLimitSchema`.

The `cpu` and `memory` fields SHALL each contain `request` and `limit` string fields with existing validation patterns (`^[0-9]+m$` for CPU, `^[0-9]+[MG]i$` for memory).

The `auto` field SHALL be optional and, when present, define vertical autoscaling behavior.

#### Scenario: Static sizing with CPU and memory

- **WHEN** a component specifies `sizing: { cpu: { request: "100m", limit: "500m" }, memory: { request: "128Mi", limit: "256Mi" } }`
- **THEN** the schema SHALL validate successfully

#### Scenario: Sizing with only CPU

- **WHEN** a component specifies `sizing: { cpu: { request: "100m", limit: "500m" } }` without memory
- **THEN** the schema SHALL validate successfully with `memory` absent

#### Scenario: Sizing with only memory

- **WHEN** a component specifies `sizing: { memory: { request: "128Mi", limit: "256Mi" } }` without CPU
- **THEN** the schema SHALL validate successfully with `cpu` absent

#### Scenario: Invalid CPU format

- **WHEN** a component specifies `sizing: { cpu: { request: "0.5", limit: "1.0" } }`
- **THEN** the schema SHALL reject the value at validation time (must match `^[0-9]+m$`)

#### Scenario: Invalid memory format

- **WHEN** a component specifies `sizing: { memory: { request: "128M", limit: "256M" } }`
- **THEN** the schema SHALL reject the value at validation time (must match `^[0-9]+[MG]i$`)

### Requirement: VerticalAutoscalingSpec definition

The `#VerticalAutoscalingSpec` SHALL define vertical autoscaling parameters within the `auto` field of `#SizingSchema`.

It MAY include `updateMode` constrained to `"Auto"`, `"Initial"`, or `"Off"` (default `"Auto"`). It MAY include `controlledResources` as a list of `"cpu"` or `"memory"` values.

#### Scenario: VPA with default update mode

- **WHEN** a component specifies `sizing: { cpu: { request: "100m", limit: "500m" }, auto: {} }`
- **THEN** the schema SHALL validate successfully with `updateMode` defaulting to `"Auto"`

#### Scenario: VPA with explicit update mode

- **WHEN** a component specifies `sizing: { auto: { updateMode: "Initial" } }`
- **THEN** the schema SHALL validate successfully

#### Scenario: VPA with controlled resources

- **WHEN** a component specifies `sizing: { auto: { controlledResources: ["cpu"] } }`
- **THEN** the schema SHALL validate successfully

#### Scenario: VPA with invalid update mode

- **WHEN** a component specifies `sizing: { auto: { updateMode: "Invalid" } }`
- **THEN** the schema SHALL reject the value at validation time

### Requirement: Trait and FQN rename

The trait definition SHALL use `name: "sizing"`, producing FQN `opmodel.dev/traits/workload@v0#Sizing`. All definition identifiers SHALL be renamed: `#SizingTrait`, `#Sizing`, `#SizingDefaults`.

The trait file SHALL be `traits/workload/sizing.cue`.

#### Scenario: FQN computation

- **WHEN** the trait metadata specifies `apiVersion: "opmodel.dev/traits/workload@v0"` and `name: "sizing"`
- **THEN** the computed FQN SHALL be `opmodel.dev/traits/workload@v0#Sizing`

### Requirement: Spec field rename

All component `spec` fields formerly named `resourceLimit` SHALL be renamed to `sizing`. This applies to workload schemas, blueprints, transformers, and examples.

#### Scenario: Workload schema field

- **WHEN** a workload component defines sizing
- **THEN** the field SHALL be `sizing?: #SizingSchema` (not `resourceLimit?`)

#### Scenario: Transformer reads sizing

- **WHEN** a Kubernetes transformer extracts resource limits
- **THEN** it SHALL read from `#component.spec.sizing` (not `#component.spec.resourceLimit`)
