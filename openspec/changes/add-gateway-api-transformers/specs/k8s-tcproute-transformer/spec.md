## ADDED Requirements

### Requirement: TCPRoute transformer definition

The Kubernetes provider SHALL include a `#TcpRouteTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the TcpRoute trait FQN (`opmodel.dev/traits/network@v0#TcpRoute`). It SHALL have no `requiredLabels` and no `requiredResources`.

#### Scenario: Transformer matches component with TcpRoute trait

- **WHEN** a component has `#TcpRouteTrait` in its `#traits`
- **THEN** the `#TcpRouteTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without TcpRoute trait

- **WHEN** a component does not have `#TcpRouteTrait` in its `#traits`
- **THEN** the `#TcpRouteTransformer` SHALL NOT match

### Requirement: TCPRoute output structure

The transformer SHALL emit a valid `gateway.networking.k8s.io/v1alpha2 TCPRoute` object. The output SHALL include `apiVersion: "gateway.networking.k8s.io/v1alpha2"`, `kind: "TCPRoute"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` derived from the TcpRoute trait.

#### Scenario: Basic TCPRoute

- **WHEN** a component named "db-proxy" defines a TcpRoute trait with `rules: [{ backendPort: 5432 }]`
- **THEN** the output SHALL be a TCPRoute with one rule containing `backendRefs: [{ name: "db-proxy", port: 5432, kind: "Service" }]`

#### Scenario: Gateway parent reference

- **WHEN** a component defines a TcpRoute trait with `gatewayRef: { name: "tcp-gateway", namespace: "infra" }`
- **THEN** the output TCPRoute SHALL include `spec.parentRefs` with one entry: `name: "tcp-gateway"`, `namespace: "infra"`

#### Scenario: No gateway reference

- **WHEN** a component defines a TcpRoute trait without `gatewayRef`
- **THEN** the output TCPRoute SHALL NOT include `spec.parentRefs`

#### Scenario: Multiple rules

- **WHEN** a component defines multiple TcpRoute rules with different backend ports
- **THEN** the output TCPRoute SHALL produce one `spec.rules` entry per OPM rule, each with its own `backendRefs`

### Requirement: Provider registration

The `#TcpRouteTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the TCPRoute transformer

### Requirement: Metadata conventions

The transformer SHALL follow standard metadata conventions.

#### Scenario: Metadata structure

- **WHEN** evaluating `#TcpRouteTransformer.metadata`
- **THEN** it SHALL have `apiVersion: "opmodel.dev/providers/kubernetes/transformers@v0"`, `name: "tcp-route-transformer"`, and labels `"core.opmodel.dev/trait-type": "network"` and `"core.opmodel.dev/resource-type": "tcproute"`

### Requirement: Test data

A test component exercising the TCPRoute transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the TCPRoute transformer test data SHALL validate successfully
