## ADDED Requirements

### Requirement: ScalingSchema struct definition

The `#ScalingSchema` SHALL be a CUE struct with a `count` field and an optional `auto` field, replacing the bare-int `#ReplicasSchema`.

The `count` field SHALL accept an integer in the range 1–1000 with a default of 1.

The `auto` field SHALL be optional and, when present, define autoscaling behavior with `min`, `max`, `metrics`, and optional `behavior` fields.

#### Scenario: Static scaling with explicit count

- **WHEN** a component specifies `scaling: { count: 3 }`
- **THEN** the schema SHALL validate successfully with `count` equal to `3` and `auto` absent

#### Scenario: Static scaling with default count

- **WHEN** a component specifies `scaling: {}` without an explicit `count`
- **THEN** the schema SHALL validate successfully with `count` defaulting to `1`

#### Scenario: Count out of range

- **WHEN** a component specifies `scaling: { count: 0 }` or `scaling: { count: 1001 }`
- **THEN** the schema SHALL reject the value at validation time

### Requirement: AutoscalingSpec definition

The `#AutoscalingSpec` SHALL define autoscaling parameters within the `auto` field of `#ScalingSchema`.

It SHALL require `min` (int >= 1), `max` (int >= 1), and `metrics` (non-empty list). It MAY include a `behavior` field for scale-up/scale-down stabilization.

#### Scenario: Autoscaling with CPU metric

- **WHEN** a component specifies `scaling: { auto: { min: 2, max: 10, metrics: [{ type: "cpu", target: { averageUtilization: 70 } }] } }`
- **THEN** the schema SHALL validate successfully

#### Scenario: Autoscaling with multiple metrics

- **WHEN** a component specifies `scaling: { auto: { min: 1, max: 20, metrics: [{ type: "cpu", target: { averageUtilization: 80 } }, { type: "memory", target: { averageUtilization: 75 } }] } }`
- **THEN** the schema SHALL validate successfully

#### Scenario: Autoscaling with custom metric

- **WHEN** a component specifies a metric with `type: "custom"` and a `metricName` field
- **THEN** the schema SHALL validate successfully and the `metricName` field SHALL be required

#### Scenario: Autoscaling missing required fields

- **WHEN** a component specifies `scaling: { auto: { min: 2 } }` without `max` or `metrics`
- **THEN** the schema SHALL reject the value at validation time

#### Scenario: Autoscaling with behavior

- **WHEN** a component specifies `scaling: { auto: { min: 1, max: 10, metrics: [...], behavior: { scaleDown: { stabilizationWindowSeconds: 300 } } } }`
- **THEN** the schema SHALL validate successfully

### Requirement: Static count and auto coexistence

When both `count` and `auto` are present, `count` SHALL represent the initial replica count before autoscaling takes effect. The `auto.min` and `auto.max` fields define the autoscaling range independently.

#### Scenario: Both count and auto specified

- **WHEN** a component specifies `scaling: { count: 3, auto: { min: 2, max: 10, metrics: [...] } }`
- **THEN** the schema SHALL validate successfully with `count` as the initial value and `auto` defining the scaling range

### Requirement: Metric target specification

Each metric in the `metrics` list SHALL have a `type` field constrained to `"cpu"`, `"memory"`, or `"custom"`, and a `target` struct.

The `target` struct SHALL support `averageUtilization` (int, 1–100) and `averageValue` (string). At least one of these fields MUST be present.

#### Scenario: Target with averageUtilization

- **WHEN** a metric specifies `target: { averageUtilization: 80 }`
- **THEN** the schema SHALL validate successfully

#### Scenario: Target with averageValue

- **WHEN** a metric specifies `target: { averageValue: "100m" }`
- **THEN** the schema SHALL validate successfully

#### Scenario: Target with no fields

- **WHEN** a metric specifies `target: {}` with neither `averageUtilization` nor `averageValue`
- **THEN** the schema SHALL reject the value at validation time

### Requirement: Trait and FQN rename

The trait definition SHALL use `name: "scaling"`, producing FQN `opmodel.dev/traits/workload@v0#Scaling`. All definition identifiers SHALL be renamed: `#ScalingTrait`, `#Scaling`, `#ScalingDefaults`.

The trait file SHALL be `traits/workload/scaling.cue`.

#### Scenario: FQN computation

- **WHEN** the trait metadata specifies `apiVersion: "opmodel.dev/traits/workload@v0"` and `name: "scaling"`
- **THEN** the computed FQN SHALL be `opmodel.dev/traits/workload@v0#Scaling`

### Requirement: Spec field rename

All component `spec` fields formerly named `replicas` SHALL be renamed to `scaling`. This applies to workload schemas (`#StatelessWorkloadSchema`, `#StatefulWorkloadSchema`), blueprints, transformers, and examples.

#### Scenario: StatelessWorkloadSchema field

- **WHEN** a stateless workload component defines scaling
- **THEN** the field SHALL be `scaling?: #ScalingSchema` (not `replicas?`)

#### Scenario: Transformer reads scaling

- **WHEN** a Kubernetes Deployment transformer extracts the replica count
- **THEN** it SHALL read from `#component.spec.scaling.count` (not `#component.spec.replicas`)

#### Scenario: Example config fields

- **WHEN** an example module defines user-facing config for replica count
- **THEN** config fields SHALL use `scaling` naming (e.g., `#config.web.scaling`)
