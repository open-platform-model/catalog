## Requirements

### Requirement: GrpcRoute schema definition

The schemas module SHALL define a `#GrpcRouteSchema` that embeds `#RouteAttachmentSchema` and specifies gRPC routing rules. The schema SHALL include an optional `hostnames` field (list of strings) for host-based matching. The schema SHALL include a required `rules` field (list, minimum one entry) where each rule embeds `#RouteRuleBase` and adds an optional `matches` list. Each match entry SHALL support optional fields: `service` (string, the fully-qualified gRPC service name), `method` (string, the gRPC method name), and `headers` (list of `#RouteHeaderMatch`).

#### Scenario: Schema validates a basic gRPC route with service matching

- **WHEN** a component specifies `grpcRoute: { rules: [{ matches: [{ service: "myapp.v1.UserService" }], backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates service and method matching

- **WHEN** a component specifies `grpcRoute: { rules: [{ matches: [{ service: "myapp.v1.UserService", method: "GetUser" }], backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates host-based gRPC routing

- **WHEN** a component specifies `grpcRoute: { hostnames: ["grpc.example.com"], rules: [{ backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates header matching on gRPC

- **WHEN** a component specifies `grpcRoute: { rules: [{ matches: [{ headers: [{ name: "x-tenant", value: "acme" }] }], backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema rejects empty rules

- **WHEN** a component specifies `grpcRoute: { rules: [] }`
- **THEN** the schema SHALL reject the value because at least one rule MUST be present

#### Scenario: Schema accepts gateway reference

- **WHEN** a component specifies `grpcRoute: { gatewayRef: { name: "grpc-gateway" }, rules: [{ backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema accepts TLS configuration

- **WHEN** a component specifies `grpcRoute: { tls: { mode: "Terminate", certificateRef: { name: "grpc-cert" } }, rules: [{ backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema accepts ingressClassName

- **WHEN** a component specifies `grpcRoute: { ingressClassName: "istio", rules: [{ backendPort: 9090 }] }`
- **THEN** the schema SHALL accept the value

### Requirement: GrpcRoute trait definition

The traits module SHALL define a `#GrpcRouteTrait` in `traits/network/grpc_route.cue` that wraps `#GrpcRouteSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `rules: [{backendPort: 9090}]` as a sensible starting point.

#### Scenario: Trait composes with a component

- **WHEN** a component includes `#Container` resource and `#GrpcRoute` trait
- **THEN** the component SHALL validate successfully and expose `spec.grpcRoute` in its spec

### Requirement: GrpcRoute trait semantically depends on Expose

The GrpcRoute trait SHALL semantically depend on the Expose trait. This dependency SHALL be enforced by the transformer, not by the trait definition itself.

#### Scenario: Transformer enforces the Expose dependency

- **WHEN** a transformer for GrpcRoute evaluates a component
- **THEN** the transformer SHALL require both the GrpcRoute trait and the Expose trait
