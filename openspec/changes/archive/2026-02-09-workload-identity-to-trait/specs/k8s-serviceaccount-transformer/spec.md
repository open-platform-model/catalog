## MODIFIED Requirements

### Requirement: ServiceAccount transformer definition

The Kubernetes provider SHALL include a `#ServiceAccountTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the WorkloadIdentity trait FQN (`opmodel.dev/traits/security@v0#WorkloadIdentity`). It SHALL have no `requiredLabels`, no `requiredResources`, and empty `optionalResources`.

#### Scenario: Transformer matches component with WorkloadIdentity trait

- **WHEN** a component has `#WorkloadIdentityTrait` in its `#traits`
- **THEN** the `#ServiceAccountTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without WorkloadIdentity trait

- **WHEN** a component does not have `#WorkloadIdentityTrait` in its `#traits`
- **THEN** the `#ServiceAccountTransformer` SHALL not match

### Requirement: Workload transformers reference ServiceAccount

When a component has a WorkloadIdentity trait, all workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) SHALL include `spec.template.spec.serviceAccountName` in their output, set to the WorkloadIdentity name. WorkloadIdentity SHALL be declared in each workload transformer's `optionalTraits` map using the trait FQN `opmodel.dev/traits/security@v0#WorkloadIdentity`.

#### Scenario: Deployment references ServiceAccount

- **WHEN** a stateless component has a Container resource and a WorkloadIdentity trait with `name: "my-app"`
- **THEN** the Deployment transformer output SHALL include `spec.template.spec.serviceAccountName: "my-app"`

#### Scenario: No serviceAccountName when WorkloadIdentity is absent

- **WHEN** a stateless component has a Container resource but no WorkloadIdentity trait
- **THEN** the Deployment transformer output SHALL NOT include `spec.template.spec.serviceAccountName`

### Requirement: Test data

A test component exercising the ServiceAccount transformer SHALL exist in the transformers test data file. The test component SHALL use `#traits` to attach `#WorkloadIdentityTrait` instead of `#resources`.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the ServiceAccount transformer test data SHALL validate successfully

#### Scenario: Test component uses trait-based composition

- **WHEN** the test component for ServiceAccount is inspected
- **THEN** it SHALL have `#WorkloadIdentityTrait` in its `#traits` map and SHALL NOT reference `#WorkloadIdentityResource` in `#resources`
