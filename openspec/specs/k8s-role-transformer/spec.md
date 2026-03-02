## Purpose

Defines the Kubernetes transformer for the OPM Role resource, converting a single Role to namespace-scoped (Role + RoleBinding) or cluster-scoped (ClusterRole + ClusterRoleBinding) RBAC objects.

## Requirements

### Requirement: Role transformer definition

The Kubernetes provider SHALL include a `#RoleTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredResources` containing the Role resource FQN. It SHALL have no `requiredLabels`, no `requiredTraits`, and empty `optionalTraits`.

#### Scenario: Transformer matches component with Role resource

- **WHEN** a component has `#RoleResource` in its `#resources`
- **THEN** the `#RoleTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without Role resource

- **WHEN** a component does not have `#RoleResource` in its `#resources`
- **THEN** the `#RoleTransformer` SHALL not match

### Requirement: Role transformer generates namespace-scoped RBAC objects

When a Role resource has `scope: "namespace"`, the transformer SHALL emit a list containing a Kubernetes `rbac.authorization.k8s.io/v1/Role` and a `rbac.authorization.k8s.io/v1/RoleBinding`.

#### Scenario: Namespace-scoped Role output

- **WHEN** a component defines a Role resource with `scope: "namespace"`, `name: "pod-reader"`, one rule `{apiGroups: [""], resources: ["pods"], verbs: ["get", "list"]}`, and one subject referencing a ServiceAccount with `name: "ci-bot"`
- **THEN** the transformer SHALL output a list containing:
  - A k8s `Role` with `metadata.name: "pod-reader"`, `metadata.namespace` from context, and `rules` matching the OPM rule
  - A k8s `RoleBinding` with `metadata.name: "pod-reader"`, `metadata.namespace` from context, `roleRef` pointing to the Role, and `subjects` containing `{kind: "ServiceAccount", name: "ci-bot"}`

### Requirement: Role transformer generates cluster-scoped RBAC objects

When a Role resource has `scope: "cluster"`, the transformer SHALL emit a list containing a Kubernetes `rbac.authorization.k8s.io/v1/ClusterRole` and a `rbac.authorization.k8s.io/v1/ClusterRoleBinding`.

#### Scenario: Cluster-scoped Role output

- **WHEN** a component defines a Role resource with `scope: "cluster"`, `name: "cluster-reader"`, one rule, and one subject referencing a WorkloadIdentity with `name: "my-app"`
- **THEN** the transformer SHALL output a list containing:
  - A k8s `ClusterRole` with `metadata.name: "cluster-reader"` and `rules` matching the OPM rule
  - A k8s `ClusterRoleBinding` with `metadata.name: "cluster-reader"`, `roleRef` pointing to the ClusterRole, and `subjects` containing `{kind: "ServiceAccount", name: "my-app"}`

#### Scenario: Cluster-scoped objects have no namespace

- **WHEN** the transformer generates ClusterRole and ClusterRoleBinding outputs
- **THEN** `metadata.namespace` SHALL NOT be present on either object

### Requirement: Role transformer extracts subject names from embedded identities

The transformer SHALL read the `name` field directly from each subject (embedded via CUE reference) to populate the k8s RoleBinding/ClusterRoleBinding `subjects` array.

#### Scenario: Multiple subjects

- **WHEN** a Role resource has two subjects referencing identities with `name: "app-a"` and `name: "app-b"`
- **THEN** the k8s RoleBinding `subjects` array SHALL contain two entries with `name: "app-a"` and `name: "app-b"`, both with `kind: "ServiceAccount"`

### Requirement: Role component carries list-output annotation

The `#Role` component mixin SHALL include `"transformer.opmodel.dev/list-output": true` in its `metadata.annotations`, because the transformer emits multiple k8s objects.

#### Scenario: Annotation is present

- **WHEN** `#Role` component mixin is evaluated
- **THEN** `metadata.annotations["transformer.opmodel.dev/list-output"]` SHALL be `true`

### Requirement: Role transformer applies context metadata

The transformer SHALL apply `#TransformerContext` labels and component annotations to all generated k8s objects.

#### Scenario: Labels applied to both Role and RoleBinding

- **WHEN** the transformer generates namespace-scoped output with context labels `{"app": "my-app"}`
- **THEN** both the k8s Role and RoleBinding SHALL have `metadata.labels` containing `{"app": "my-app"}`

### Requirement: Provider registration

The `#RoleTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the Role transformer

### Requirement: Test data

Test components exercising the Role transformer SHALL exist in the transformers test data, covering both namespace and cluster scope.

#### Scenario: Namespace-scoped test validates

- **WHEN** `task vet` is run on the providers module
- **THEN** the namespace-scoped Role transformer test data SHALL validate successfully

#### Scenario: Cluster-scoped test validates

- **WHEN** `task vet` is run on the providers module
- **THEN** the cluster-scoped Role transformer test data SHALL validate successfully
