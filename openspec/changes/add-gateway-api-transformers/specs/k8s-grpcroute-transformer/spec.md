## ADDED Requirements

### Requirement: GRPCRoute transformer definition

The Kubernetes provider SHALL include a `#GrpcRouteTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the GrpcRoute trait FQN (`opmodel.dev/traits/network@v0#GrpcRoute`). It SHALL have no `requiredLabels` and no `requiredResources`.

#### Scenario: Transformer matches component with GrpcRoute trait

- **WHEN** a component has `#GrpcRouteTrait` in its `#traits`
- **THEN** the `#GrpcRouteTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without GrpcRoute trait

- **WHEN** a component does not have `#GrpcRouteTrait` in its `#traits`
- **THEN** the `#GrpcRouteTransformer` SHALL NOT match

### Requirement: GRPCRoute output structure

The transformer SHALL emit a valid `gateway.networking.k8s.io/v1 GRPCRoute` object. The output SHALL include `apiVersion: "gateway.networking.k8s.io/v1"`, `kind: "GRPCRoute"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` derived from the GrpcRoute trait.

#### Scenario: Basic GRPCRoute with service matching

- **WHEN** a component defines a GrpcRoute trait with `hostnames: ["grpc.example.com"]` and `rules: [{ matches: [{ service: "mypackage.MyService" }], backendPort: 9090 }]`
- **THEN** the output SHALL be a GRPCRoute with `spec.hostnames: ["grpc.example.com"]` and one rule with a match for `method.service: "mypackage.MyService"`, with `backendRefs` on port 9090

#### Scenario: Method matching

- **WHEN** a component defines a GrpcRoute rule with `matches: [{ service: "mypackage.MyService", method: "GetUser" }]`
- **THEN** the GRPCRoute rule match SHALL include `method: { service: "mypackage.MyService", method: "GetUser", type: "Exact" }`

#### Scenario: Header matching

- **WHEN** a component defines a GrpcRoute rule with `matches: [{ headers: [{ name: "x-tenant", value: "acme" }] }]`
- **THEN** the GRPCRoute rule match SHALL include `headers: [{ name: "x-tenant", value: "acme", type: "Exact" }]`

#### Scenario: Gateway parent reference

- **WHEN** a component defines a GrpcRoute trait with `gatewayRef: { name: "my-gateway" }`
- **THEN** the output GRPCRoute SHALL include `spec.parentRefs` with one entry: `name: "my-gateway"`

#### Scenario: No gateway reference

- **WHEN** a component defines a GrpcRoute trait without `gatewayRef`
- **THEN** the output GRPCRoute SHALL NOT include `spec.parentRefs`

#### Scenario: Backend references the component Service

- **WHEN** a component named "grpc-api" with GrpcRoute trait (`rules: [{ backendPort: 9090 }]`) is transformed
- **THEN** each rule's `backendRefs` SHALL contain `name: "grpc-api"`, `port: 9090`, and `kind: "Service"`

#### Scenario: No matches (catch-all rule)

- **WHEN** a component defines a GrpcRoute rule without `matches`
- **THEN** the GRPCRoute rule SHALL have no `matches` field and SHALL include `backendRefs`

#### Scenario: No hostnames

- **WHEN** a component defines a GrpcRoute trait without `hostnames`
- **THEN** the output GRPCRoute SHALL NOT include `spec.hostnames`

### Requirement: Provider registration

The `#GrpcRouteTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the GRPCRoute transformer

### Requirement: Metadata conventions

The transformer SHALL follow standard metadata conventions.

#### Scenario: Metadata structure

- **WHEN** evaluating `#GrpcRouteTransformer.metadata`
- **THEN** it SHALL have `apiVersion: "opmodel.dev/providers/kubernetes/transformers@v0"`, `name: "grpc-route-transformer"`, and labels `"core.opmodel.dev/trait-type": "network"` and `"core.opmodel.dev/resource-type": "grpcroute"`

### Requirement: Test data

A test component exercising the GRPCRoute transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the GRPCRoute transformer test data SHALL validate successfully
