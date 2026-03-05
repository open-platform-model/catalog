## ADDED Requirements

### Requirement: Gateway API v1 CUE type definitions

The module `opmodel.dev/schemas/kubernetes@v0` SHALL provide hand-written CUE type definitions for Kubernetes Gateway API `gateway.networking.k8s.io/v1` resources at `gateway/v1/types.cue`. The definitions SHALL cover `#HTTPRoute`, `#GRPCRoute`, and all supporting types needed by the transformers.

#### Scenario: Import gateway/v1 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/gateway/v1`
- **THEN** the package SHALL provide `#HTTPRoute`, `#HTTPRouteSpec`, `#HTTPRouteRule`, `#HTTPRouteMatch`, `#HTTPPathMatch`, `#HTTPHeaderMatch`, `#HTTPBackendRef`, `#GRPCRoute`, `#GRPCRouteSpec`, `#GRPCRouteRule`, `#GRPCRouteMatch`, `#GRPCMethodMatch`, `#GRPCHeaderMatch`, `#GRPCBackendRef`, `#ParentReference`, `#BackendObjectReference`, and `#CommonRouteSpec`

#### Scenario: HTTPRoute type structure

- **WHEN** evaluating `#HTTPRoute`
- **THEN** it SHALL contain `apiVersion: "gateway.networking.k8s.io/v1"`, `kind: "HTTPRoute"`, and optional `metadata` and `spec` fields conforming to the Gateway API specification

#### Scenario: GRPCRoute type structure

- **WHEN** evaluating `#GRPCRoute`
- **THEN** it SHALL contain `apiVersion: "gateway.networking.k8s.io/v1"`, `kind: "GRPCRoute"`, and optional `metadata` and `spec` fields conforming to the Gateway API specification

### Requirement: Gateway API v1alpha2 CUE type definitions

The module SHALL provide hand-written CUE type definitions for Kubernetes Gateway API `gateway.networking.k8s.io/v1alpha2` resources at `gateway/v1alpha2/types.cue`.

#### Scenario: Import gateway/v1alpha2 types

- **WHEN** a CUE file imports `opmodel.dev/schemas/kubernetes/gateway/v1alpha2`
- **THEN** the package SHALL provide `#TCPRoute`, `#TCPRouteSpec`, `#TCPRouteRule`, and `#TCPBackendRef`

#### Scenario: TCPRoute type structure

- **WHEN** evaluating `#TCPRoute`
- **THEN** it SHALL contain `apiVersion: "gateway.networking.k8s.io/v1alpha2"`, `kind: "TCPRoute"`, and optional `metadata` and `spec` fields conforming to the Gateway API specification

### Requirement: Shared Gateway API types

Shared types used across v1 and v1alpha2 definitions SHALL be defined in `gateway/v1/types.cue` (since v1 is the primary version).

#### Scenario: ParentReference structure

- **WHEN** evaluating `#ParentReference`
- **THEN** it SHALL have `name!: string` (required), and optional fields `group`, `kind`, `namespace`, `sectionName`, and `port`

#### Scenario: BackendObjectReference structure

- **WHEN** evaluating `#BackendObjectReference`
- **THEN** it SHALL have `name!: string` (required), and optional fields `group`, `kind`, `namespace`, and `port`

### Requirement: Type definitions validate

All Gateway API CUE type definitions SHALL pass CUE validation.

#### Scenario: Format validation

- **WHEN** running `task fmt MODULE=schemas_kubernetes`
- **THEN** all gateway type files SHALL be properly formatted

#### Scenario: Vet validation

- **WHEN** running `task vet MODULE=schemas_kubernetes`
- **THEN** validation SHALL pass without errors
