## Why

The Kubernetes provider currently only supports `networking.k8s.io/v1 Ingress` for HTTP routing via the `IngressTransformer`. Gateway API (`gateway.networking.k8s.io`) is the successor to Ingress in Kubernetes, offering richer routing semantics (gRPC-native, TCP/UDP, header-based matching, traffic splitting) and is the recommended approach for new clusters. The OPM trait schemas (`#HttpRouteSchema`, `#GrpcRouteSchema`, `#TcpRouteSchema`) already include `gatewayRef` in `#RouteAttachmentSchema`, but no transformers consume it. The gRPC and TCP route traits currently have no Kubernetes transformers at all.

## What Changes

- **Add hand-written Gateway API CUE type definitions** in `v0/schemas_kubernetes/gateway/` for `HTTPRoute`, `GRPCRoute`, `TCPRoute`, and shared types (`ParentReference`, `BackendRef`, etc.).
- **Add `#HttpRouteTransformer`** — converts `#HttpRouteTrait` to `gateway.networking.k8s.io/v1 HTTPRoute`. This is the primary routing transformer; always produces output when the trait is present.
- **Add `#GrpcRouteTransformer`** — converts `#GrpcRouteTrait` to `gateway.networking.k8s.io/v1 GRPCRoute`.
- **Add `#TcpRouteTransformer`** — converts `#TcpRouteTrait` to `gateway.networking.k8s.io/v1alpha2 TCPRoute`.
- **Modify `#IngressTransformer`** — make it a fallback: only produces output when `ingressClassName` is explicitly set AND `gatewayRef` is absent. This is a **BREAKING** behavioral change for users relying on Ingress without setting `ingressClassName`.
- **Register all new transformers** in the Kubernetes `#Provider`.
- **Add test data and tests** for all new transformers and the modified Ingress behavior.

## Capabilities

### New Capabilities
- `k8s-gateway-api-types`: Hand-written CUE type definitions for Kubernetes Gateway API resources (HTTPRoute, GRPCRoute, TCPRoute, shared types) in `v0/schemas_kubernetes/gateway/`.
- `k8s-httproute-transformer`: Transformer converting `#HttpRouteTrait` to Gateway API `HTTPRoute`. Primary HTTP routing path.
- `k8s-grpcroute-transformer`: Transformer converting `#GrpcRouteTrait` to Gateway API `GRPCRoute`.
- `k8s-tcproute-transformer`: Transformer converting `#TcpRouteTrait` to Gateway API `TCPRoute`.

### Modified Capabilities
- `k8s-ingress-transformer`: Behavioral change — Ingress output now conditional on `ingressClassName` being set and `gatewayRef` being absent. Becomes explicit fallback instead of default.

## Impact

- **CUE modules affected**: `schemas_kubernetes` (new gateway types), `providers` (new transformers + modified ingress transformer)
- **SemVer**: MINOR — adds new transformers (non-breaking additions), but the Ingress behavioral change is **BREAKING** for users who relied on Ingress output without setting `ingressClassName`. Given the project is under heavy development, this is acceptable as a minor bump.
- **Dependencies**: No new external CUE dependencies. Gateway API types are hand-written.
- **Portability**: No portability concern — all changes are within the Kubernetes provider. The OPM trait schemas are unchanged.
- **API surface**: Non-breaking for traits. Breaking for provider output behavior (Ingress fallback).
