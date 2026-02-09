## ADDED Requirements

### Requirement: ServiceAccount transformer definition

The Kubernetes provider SHALL include a `#ServiceAccountTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the WorkloadIdentity resource FQN. It SHALL have no `requiredLabels` and no `requiredTraits`.

#### Scenario: Transformer matches component with WorkloadIdentity resource

- **WHEN** a component has `#WorkloadIdentityResource` in its `#resources`
- **THEN** the `#ServiceAccountTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without WorkloadIdentity resource

- **WHEN** a component does not have `#WorkloadIdentityResource` in its `#resources`
- **THEN** the `#ServiceAccountTransformer` SHALL not match

### Requirement: ServiceAccount output structure

The transformer SHALL emit a valid Kubernetes `v1/ServiceAccount` object. The output SHALL include `apiVersion: "v1"`, `kind: "ServiceAccount"`, and `metadata` with name, namespace, and labels from `#TransformerContext`. The `automountServiceAccountToken` field SHALL be set from the WorkloadIdentity resource's `automountToken` field.

#### Scenario: ServiceAccount with token automount disabled

- **WHEN** a component defines a WorkloadIdentity resource with `name: "my-app"` and `automountToken: false`
- **THEN** the output SHALL be a ServiceAccount with `metadata.name: "my-app"` and `automountServiceAccountToken: false`

#### Scenario: Default automount is false

- **WHEN** a component defines a WorkloadIdentity resource without specifying `automountToken`
- **THEN** the output ServiceAccount SHALL have `automountServiceAccountToken: false`

### Requirement: Workload transformers reference ServiceAccount

When a component has a WorkloadIdentity resource, all workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) SHALL include `spec.template.spec.serviceAccountName` in their output, set to the WorkloadIdentity name.

#### Scenario: Deployment references ServiceAccount

- **WHEN** a stateless component has both a Container resource and a WorkloadIdentity resource with `name: "my-app"`
- **THEN** the Deployment transformer output SHALL include `spec.template.spec.serviceAccountName: "my-app"`

#### Scenario: No serviceAccountName when WorkloadIdentity is absent

- **WHEN** a stateless component has a Container resource but no WorkloadIdentity resource
- **THEN** the Deployment transformer output SHALL NOT include `spec.template.spec.serviceAccountName`

### Requirement: Provider registration

The `#ServiceAccountTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the ServiceAccount transformer

### Requirement: Test data

A test component exercising the ServiceAccount transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the ServiceAccount transformer test data SHALL validate successfully
