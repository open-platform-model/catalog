## ADDED Requirements

### Requirement: Module provides Kubernetes schema re-exports

The module `opmodel.dev/schemas/kubernetes@v0` SHALL re-export upstream Kubernetes CUE schemas from `cue.dev/x/k8s.io@v0` with explicit type definitions.

#### Scenario: Import apps/v1 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/apps/v1`
- **THEN** the package SHALL provide `#Deployment`, `#StatefulSet`, `#DaemonSet`, `#ReplicaSet`, and all related types from the upstream `apps/v1` API group

#### Scenario: Import core/v1 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/core/v1`
- **THEN** the package SHALL provide `#Pod`, `#Service`, `#ConfigMap`, `#Secret`, `#PersistentVolumeClaim`, `#ServiceAccount`, and all related types from the upstream `core/v1` API group

#### Scenario: Import batch/v1 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/batch/v1`
- **THEN** the package SHALL provide `#Job`, `#CronJob`, and all related types from the upstream `batch/v1` API group

#### Scenario: Import networking/v1 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/networking/v1`
- **THEN** the package SHALL provide `#Ingress`, `#IngressClass`, `#NetworkPolicy`, and all related types from the upstream `networking/v1` API group

#### Scenario: Import autoscaling/v2 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/autoscaling/v2`
- **THEN** the package SHALL provide `#HorizontalPodAutoscaler` and all related types from the upstream `autoscaling/v2` API group

### Requirement: Re-exports use explicit definitions

Each type file SHALL explicitly list all re-exported definitions rather than using package-level embedding.

#### Scenario: Explicit type mapping

- **WHEN** viewing a types.cue file in any API group package
- **THEN** each K8s type SHALL be explicitly assigned (e.g., `#Deployment: appsv1.#Deployment`)

### Requirement: Upstream dependency pinned to specific version

The module SHALL pin its dependency on `cue.dev/x/k8s.io@v0` to version `v0.6.0`.

#### Scenario: Module dependency check

- **WHEN** inspecting `v0/schemas_kubernetes/cue.mod/module.cue`
- **THEN** the deps section SHALL contain `"cue.dev/x/k8s.io@v0": { v: "v0.6.0" }`

### Requirement: Module validates with CUE tooling

The module SHALL pass all CUE validation gates.

#### Scenario: Format validation

- **WHEN** running `task fmt MODULE=schemas_kubernetes`
- **THEN** all CUE files SHALL be properly formatted

#### Scenario: Vet validation

- **WHEN** running `task vet MODULE=schemas_kubernetes`
- **THEN** validation SHALL pass without errors

### Requirement: Future API groups documented

The module SHALL document remaining K8s API groups available for future expansion.

#### Scenario: Documentation includes future groups

- **WHEN** viewing module documentation or comments
- **THEN** the following API groups SHALL be listed as available for future addition: admissionregistration, apiserverinternal, authentication, authorization, certificates, coordination, discovery, events, flowcontrol, node, policy, rbac, resource, scheduling, storage, storagemigration
