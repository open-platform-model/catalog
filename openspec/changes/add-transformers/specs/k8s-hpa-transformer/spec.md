## ADDED Requirements

### Requirement: HPA transformer definition

The Kubernetes provider SHALL include a `#HPATransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the Scaling trait FQN. The transformer SHALL only produce output when the component's `scaling.auto` field is present.

#### Scenario: Transformer matches component with Scaling auto config

- **WHEN** a component has the Scaling trait and `scaling.auto` is defined
- **THEN** the `#HPATransformer` SHALL match and produce output

#### Scenario: Transformer does not produce output for static scaling

- **WHEN** a component has the Scaling trait with only `scaling.count` (no `auto`)
- **THEN** the `#HPATransformer` SHALL not produce output

### Requirement: HPA output structure

The transformer SHALL emit a valid Kubernetes `autoscaling/v2/HorizontalPodAutoscaler` object. The output SHALL include `apiVersion: "autoscaling/v2"`, `kind: "HorizontalPodAutoscaler"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` with scaling configuration.

#### Scenario: CPU-based autoscaling

- **WHEN** a component defines `scaling.auto` with `min: 2`, `max: 10`, and a CPU metric targeting `averageUtilization: 80`
- **THEN** the output SHALL be an HPA with `spec.minReplicas: 2`, `spec.maxReplicas: 10`, and a CPU resource metric with `target.averageUtilization: 80`

#### Scenario: Multiple metrics

- **WHEN** a component defines `scaling.auto` with both CPU and memory metrics
- **THEN** the output HPA SHALL include both metrics in `spec.metrics`

#### Scenario: Custom metric

- **WHEN** a component defines `scaling.auto` with a custom metric type and `metricName: "requests_per_second"`
- **THEN** the output HPA SHALL include a pods metric with the specified name

### Requirement: HPA scaleTargetRef

The HPA `spec.scaleTargetRef` SHALL reference the workload resource (Deployment, StatefulSet) that the component produces. It SHALL use `apiVersion: "apps/v1"`, the appropriate `kind`, and `name` matching the component name.

#### Scenario: HPA targets a Deployment

- **WHEN** a stateless component with `scaling.auto` is transformed
- **THEN** the HPA `spec.scaleTargetRef` SHALL have `kind: "Deployment"` and `name` matching the component name

#### Scenario: HPA targets a StatefulSet

- **WHEN** a stateful component with `scaling.auto` is transformed
- **THEN** the HPA `spec.scaleTargetRef` SHALL have `kind: "StatefulSet"` and `name` matching the component name

### Requirement: Workload transformers use auto.min for static replicas

When `scaling.auto` is present, workload transformers SHALL use `scaling.auto.min` as the value for `spec.replicas` instead of `scaling.count`, so the static value matches the HPA floor.

#### Scenario: Deployment replicas set to auto.min

- **WHEN** a stateless component has `scaling: { count: 1, auto: { min: 3, max: 10, metrics: [...] } }`
- **THEN** the Deployment transformer SHALL emit `spec.replicas: 3` (from `auto.min`, not `count`)

### Requirement: Scaling behavior

When `scaling.auto.behavior` is specified, the HPA SHALL include `spec.behavior` with scale-up and scale-down stabilization windows.

#### Scenario: Custom stabilization window

- **WHEN** a component defines `scaling.auto.behavior.scaleDown.stabilizationWindowSeconds: 300`
- **THEN** the HPA SHALL include `spec.behavior.scaleDown.stabilizationWindowSeconds: 300`

### Requirement: Provider registration

The `#HPATransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the HPA transformer

### Requirement: Test data

A test component exercising the HPA transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the HPA transformer test data SHALL validate successfully
