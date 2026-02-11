# Kubernetes Transformer Schema Validation

## Purpose

Validate Kubernetes transformer output against upstream k8s CUE schemas at evaluation time. Each transformer's output SHALL be unified with the corresponding Kubernetes resource type from `opmodel.dev/schemas/kubernetes@v0`, ensuring structural correctness before deployment.

## ADDED Requirements

### Requirement: Providers module depends on Kubernetes schemas

The `opmodel.dev/providers@v0` module SHALL declare a dependency on `opmodel.dev/schemas/kubernetes@v0` in its `cue.mod/module.cue`.

#### Scenario: Dependency declared

- **WHEN** inspecting `v0/providers/cue.mod/module.cue`
- **THEN** the deps section SHALL contain an entry for `"opmodel.dev/schemas/kubernetes@v0"`

### Requirement: Single-resource transformer output is unified with k8s schema

Each single-resource Kubernetes transformer SHALL unify its `output` field directly with the corresponding upstream k8s CUE type.

#### Scenario: Deployment transformer validates against apps/v1 Deployment

- **WHEN** the Deployment transformer produces output
- **THEN** the output SHALL be unified with `k8sappsv1.#Deployment` where `k8sappsv1` is imported from `opmodel.dev/schemas/kubernetes/apps/v1@v0`

#### Scenario: StatefulSet transformer validates against apps/v1 StatefulSet

- **WHEN** the StatefulSet transformer produces output
- **THEN** the output SHALL be unified with `k8sappsv1.#StatefulSet`

#### Scenario: DaemonSet transformer validates against apps/v1 DaemonSet

- **WHEN** the DaemonSet transformer produces output
- **THEN** the output SHALL be unified with `k8sappsv1.#DaemonSet`

#### Scenario: Job transformer validates against batch/v1 Job

- **WHEN** the Job transformer produces output
- **THEN** the output SHALL be unified with `k8sbatchv1.#Job` where `k8sbatchv1` is imported from `opmodel.dev/schemas/kubernetes/batch/v1@v0`

#### Scenario: CronJob transformer validates against batch/v1 CronJob

- **WHEN** the CronJob transformer produces output
- **THEN** the output SHALL be unified with `k8sbatchv1.#CronJob`

#### Scenario: Service transformer validates against core/v1 Service

- **WHEN** the Service transformer produces output
- **THEN** the output SHALL be unified with `k8scorev1.#Service` where `k8scorev1` is imported from `opmodel.dev/schemas/kubernetes/core/v1@v0`

#### Scenario: Ingress transformer validates against networking/v1 Ingress

- **WHEN** the Ingress transformer produces output
- **THEN** the output SHALL be unified with `k8snetv1.#Ingress` where `k8snetv1` is imported from `opmodel.dev/schemas/kubernetes/networking/v1@v0`

#### Scenario: ServiceAccount transformer validates against core/v1 ServiceAccount

- **WHEN** the ServiceAccount transformer produces output
- **THEN** the output SHALL be unified with `k8scorev1.#ServiceAccount`

### Requirement: Multi-resource transformer output validates each resource individually

Transformers that emit a map of multiple resources (identified by the `transformer.opmodel.dev/list-output` annotation) SHALL unify each value in the output map with the corresponding k8s type.

#### Scenario: ConfigMap transformer validates each ConfigMap

- **WHEN** the ConfigMap transformer produces output containing multiple ConfigMaps
- **THEN** each value in the output map SHALL be unified with `k8scorev1.#ConfigMap`

#### Scenario: Secret transformer validates each Secret

- **WHEN** the Secret transformer produces output containing multiple Secrets
- **THEN** each value in the output map SHALL be unified with `k8scorev1.#Secret`

#### Scenario: PVC transformer validates each PersistentVolumeClaim

- **WHEN** the PVC transformer produces output containing multiple PVCs
- **THEN** each value in the output map SHALL be unified with `k8scorev1.#PersistentVolumeClaim`

### Requirement: Conditional transformer output only validates when produced

Transformers with conditional output (where output may be empty `{}`) SHALL only apply the k8s schema constraint when the resource is actually produced.

#### Scenario: HPA transformer with auto-scaling configured

- **WHEN** the HPA transformer produces output because `scaling.auto` is defined
- **THEN** the output SHALL be unified with `k8sasv2.#HorizontalPodAutoscaler` where `k8sasv2` is imported from `opmodel.dev/schemas/kubernetes/autoscaling/v2@v0`

#### Scenario: HPA transformer without auto-scaling

- **WHEN** the HPA transformer produces empty output because `scaling.auto` is absent
- **THEN** the output SHALL remain `{}` with no k8s type fields injected

### Requirement: Workload transformer volumes field is a list

All workload transformers that emit a `volumes` field SHALL produce it as a list (`[...#Volume]`) matching the Kubernetes `PodSpec.volumes` type, not as a struct.

#### Scenario: Deployment with persistent volumes

- **WHEN** a component has persistent claim volumes defined
- **THEN** the Deployment transformer output `spec.template.spec.volumes` SHALL be a list of volume objects, each containing `name` and `persistentVolumeClaim` fields

#### Scenario: StatefulSet with persistent volumes

- **WHEN** a component has persistent claim volumes defined
- **THEN** the StatefulSet transformer output `spec.template.spec.volumes` SHALL be a list

#### Scenario: DaemonSet with persistent volumes

- **WHEN** a component has persistent claim volumes defined
- **THEN** the DaemonSet transformer output `spec.template.spec.volumes` SHALL be a list

#### Scenario: Job with persistent volumes

- **WHEN** a component has persistent claim volumes defined
- **THEN** the Job transformer output `spec.template.spec.volumes` SHALL be a list

#### Scenario: CronJob with persistent volumes

- **WHEN** a component has persistent claim volumes defined
- **THEN** the CronJob transformer output `spec.jobTemplate.spec.template.spec.volumes` SHALL be a list

### Requirement: All transformers pass CUE validation

After integration, `task vet MODULE=providers` SHALL pass without errors, confirming that all transformer outputs are structurally valid against the upstream k8s schemas.

#### Scenario: Providers module validates

- **WHEN** running `task vet MODULE=providers`
- **THEN** validation SHALL pass with no errors

#### Scenario: Providers module formats cleanly

- **WHEN** running `task fmt MODULE=providers`
- **THEN** all CUE files SHALL be properly formatted
