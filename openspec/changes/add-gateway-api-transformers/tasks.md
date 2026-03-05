## 1. Gateway API CUE Type Definitions

- [ ] 1.1 Create `v0/schemas_kubernetes/gateway/v1/types.cue` with shared types (`#ParentReference`, `#BackendObjectReference`, `#CommonRouteSpec`) and HTTP types (`#HTTPRoute`, `#HTTPRouteSpec`, `#HTTPRouteRule`, `#HTTPRouteMatch`, `#HTTPPathMatch`, `#HTTPHeaderMatch`, `#HTTPBackendRef`)
- [ ] 1.2 Add GRPCRoute types to `v0/schemas_kubernetes/gateway/v1/types.cue` (`#GRPCRoute`, `#GRPCRouteSpec`, `#GRPCRouteRule`, `#GRPCRouteMatch`, `#GRPCMethodMatch`, `#GRPCHeaderMatch`, `#GRPCBackendRef`)
- [ ] 1.3 Create `v0/schemas_kubernetes/gateway/v1alpha2/types.cue` with TCPRoute types (`#TCPRoute`, `#TCPRouteSpec`, `#TCPRouteRule`, `#TCPBackendRef`)
- [ ] 1.4 Run `task fmt MODULE=schemas_kubernetes` and `task vet MODULE=schemas_kubernetes` to validate gateway type definitions

## 2. HTTPRoute Transformer

- [ ] 2.1 Create `v0/providers/kubernetes/transformers/httproute_transformer.cue` implementing `#HttpRouteTransformer` — converts `#HttpRouteTrait` to `gateway.networking.k8s.io/v1 HTTPRoute` with parentRefs, hostnames, rules (path/header/method matching), and backendRefs mapped per design D3
- [ ] 2.2 Add test component `_testHttpRouteComponent` to `test_data.cue` with HttpRoute trait including gatewayRef, hostnames, path matches, and header matches
- [ ] 2.3 Add inline test `_testHttpRouteTransformer` in the transformer file

## 3. GRPCRoute Transformer

- [ ] 3.1 Create `v0/providers/kubernetes/transformers/grpcroute_transformer.cue` implementing `#GrpcRouteTransformer` — converts `#GrpcRouteTrait` to `gateway.networking.k8s.io/v1 GRPCRoute` with parentRefs, hostnames, rules (service/method/header matching), and backendRefs
- [ ] 3.2 Add test component `_testGrpcRouteComponent` to `test_data.cue` with GrpcRoute trait including gatewayRef, hostnames, and gRPC service/method matches
- [ ] 3.3 Add inline test `_testGrpcRouteTransformer` in the transformer file

## 4. TCPRoute Transformer

- [ ] 4.1 Create `v0/providers/kubernetes/transformers/tcproute_transformer.cue` implementing `#TcpRouteTransformer` — converts `#TcpRouteTrait` to `gateway.networking.k8s.io/v1alpha2 TCPRoute` with parentRefs, rules, and backendRefs
- [ ] 4.2 Add test component `_testTcpRouteComponent` to `test_data.cue` with TcpRoute trait including gatewayRef and backend ports
- [ ] 4.3 Add inline test `_testTcpRouteTransformer` in the transformer file

## 5. Modify Ingress Transformer (Fallback)

- [ ] 5.1 Update `v0/providers/kubernetes/transformers/ingress_transformer.cue` to wrap output in conditional: only produce Ingress when `ingressClassName` is set AND `gatewayRef` is absent
- [ ] 5.2 Update `_testIngressComponent` in `test_data.cue` to ensure it sets `ingressClassName` and does NOT set `gatewayRef` (to exercise the fallback path)
- [ ] 5.3 Verify existing inline test `_testIngressTransformer` still passes with the updated conditional

## 6. Provider Registration

- [ ] 6.1 Register `#HttpRouteTransformer`, `#GrpcRouteTransformer`, and `#TcpRouteTransformer` in `v0/providers/kubernetes/provider.cue` transformers map

## 7. Validation

- [ ] 7.1 Run `task fmt MODULE=providers` to format all transformer files
- [ ] 7.2 Run `task vet MODULE=providers` to validate all transformers and provider registration
- [ ] 7.3 Run `task vet MODULE=providers CONCRETE=true` to verify concreteness of test outputs
- [ ] 7.4 Run `task eval MODULE=providers` to inspect evaluated output and verify HTTPRoute, GRPCRoute, TCPRoute, and conditional Ingress outputs are correct
