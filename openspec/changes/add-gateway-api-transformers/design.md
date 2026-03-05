## Context

The Kubernetes provider's routing story is incomplete. Only `#IngressTransformer` exists, converting `#HttpRouteTrait` to a `networking.k8s.io/v1 Ingress`. Gateway API (`gateway.networking.k8s.io`) is the Kubernetes-native successor to Ingress, offering typed routing for HTTP, gRPC, and TCP. The OPM route schemas already have `gatewayRef` in `#RouteAttachmentSchema` and separate trait definitions for all three route types (`#HttpRouteTrait`, `#GrpcRouteTrait`, `#TcpRouteTrait`), but only HTTP has a transformer and it only produces Ingress resources.

No CUE module exists upstream for Gateway API types (`sigs.k8s.io/gateway-api` has no `cue.dev/x/` mirror). The existing K8s schema dependency is `cue.dev/x/k8s.io@v0` v0.6.0.

### Current transformer matching flow

```text
Component with #HttpRouteTrait
  └── #Matches checks requiredTraits
       └── #IngressTransformer matches → produces Ingress
```

### Target flow

```text
Component with #HttpRouteTrait
  └── #Matches checks requiredTraits
       ├── #HttpRouteTransformer matches → always produces HTTPRoute (primary)
       └── #IngressTransformer matches  → produces Ingress ONLY when
                                           ingressClassName set AND
                                           gatewayRef absent (fallback)

Component with #GrpcRouteTrait
  └── #GrpcRouteTransformer matches → produces GRPCRoute

Component with #TcpRouteTrait
  └── #TcpRouteTransformer matches → produces TCPRoute
```

## Goals / Non-Goals

**Goals:**
- Gateway API HTTPRoute, GRPCRoute, and TCPRoute transformers for the Kubernetes provider
- Gateway API as the primary routing path (no extra config needed)
- Ingress as an explicit fallback when `ingressClassName` is set without `gatewayRef`
- Hand-written CUE type definitions for Gateway API resources
- Full test coverage following the existing transformer test pattern

**Non-Goals:**
- Gateway/GatewayClass resource management (those are cluster-level resources managed by platform teams, not application components)
- TLSRoute support (not yet stable in Gateway API, can be added later)
- UDPRoute support (same rationale)
- ReferenceGrant generation (cross-namespace policy, managed separately)
- Modifying the OPM trait schemas (`#HttpRouteSchema`, `#GrpcRouteSchema`, `#TcpRouteSchema`) — they already have the right fields
- Traffic splitting / weighted backends (the OPM schemas don't model backend weights yet)

## Decisions

### D1: Hand-write Gateway API CUE types in `schemas_kubernetes`

**Decision**: Create `gateway/v1/types.cue` and `gateway/v1alpha2/types.cue` under `v0/schemas_kubernetes/` with hand-written CUE definitions.

**Rationale**: No upstream CUE module exists for `sigs.k8s.io/gateway-api`. The types needed are well-scoped (HTTPRoute, GRPCRoute, TCPRoute + shared types). Hand-writing keeps the dependency tree simple and follows the existing re-export pattern in `v0/schemas_kubernetes/`.

**Alternative considered**: Skip K8s schema validation entirely and produce raw structs. Rejected because it violates Principle I (Type Safety First) — all definitions MUST be validated at definition time.

**Types to define**:
- Shared: `#ParentReference`, `#BackendObjectReference`, `#CommonRouteSpec`, `#RouteStatus`, `#RouteParentStatus`, `#Condition`
- `gateway/v1/`: `#HTTPRoute`, `#HTTPRouteSpec`, `#HTTPRouteRule`, `#HTTPRouteMatch`, `#HTTPHeaderMatch`, `#HTTPPathMatch`, `#HTTPRouteFilter`, `#HTTPBackendRef`, `#GRPCRoute`, `#GRPCRouteSpec`, `#GRPCRouteRule`, `#GRPCRouteMatch`, `#GRPCMethodMatch`, `#GRPCHeaderMatch`, `#GRPCBackendRef`
- `gateway/v1alpha2/`: `#TCPRoute`, `#TCPRouteSpec`, `#TCPRouteRule`, `#TCPBackendRef`

### D2: Field-based conditional output for Ingress/Gateway coexistence

**Decision**: Both `#HttpRouteTransformer` and `#IngressTransformer` match any component with `#HttpRouteTrait`. The selection happens inside `#transform`:
- `#HttpRouteTransformer.output`: Always produces a Gateway API HTTPRoute (primary)
- `#IngressTransformer.output`: Wraps output in `if _httpRoute.ingressClassName != _|_ if _httpRoute.gatewayRef == _|_ { ... }` — only produces Ingress when `ingressClassName` is explicitly set AND `gatewayRef` is absent

**Rationale**: This uses the existing conditional output pattern (see HPA transformer) and the natural discriminator already present in `#RouteAttachmentSchema`. No new labels, no schema changes, no matching system changes.

**Alternative considered**: Label-based selection (`transformer.opmodel.dev/routing-backend`). Rejected because it requires users to set an extra label and breaks the principle that traits alone should drive transformer matching.

**Coexistence matrix**:

```text
┌─────────────────────┬─────────────────┬───────────────────┐
│ Route fields set    │ HTTPRoute output │ Ingress output    │
├─────────────────────┼─────────────────┼───────────────────┤
│ gatewayRef only     │  [x]            │  [ ]              │
│ ingressClassName    │  [x]            │  [x]              │
│ both                │  [x]            │  [ ]              │
│ neither             │  [x]            │  [ ]              │
└─────────────────────┴─────────────────┴───────────────────┘
```

### D3: OPM-to-Gateway field mapping

**HTTPRoute mapping** (`#HttpRouteTrait` → `gateway.networking.k8s.io/v1 HTTPRoute`):

| OPM field | Gateway API field |
|---|---|
| `gatewayRef.name` / `.namespace` | `spec.parentRefs[0].name` / `.namespace` |
| `hostnames` | `spec.hostnames` |
| `rules[].matches[].path.value` / `.type` | `spec.rules[].matches[].path.value` / `.type` |
| `rules[].matches[].headers` | `spec.rules[].matches[].headers` |
| `rules[].matches[].method` | `spec.rules[].matches[].method` |
| `rules[].backendPort` | `spec.rules[].backendRefs[0].port` |
| `component.metadata.name` | `spec.rules[].backendRefs[0].name` |
| `tls.certificateRef` | Not mapped (TLS termination is on the Gateway, not the Route) |

**GRPCRoute mapping** (`#GrpcRouteTrait` → `gateway.networking.k8s.io/v1 GRPCRoute`):

| OPM field | Gateway API field |
|---|---|
| `gatewayRef.name` / `.namespace` | `spec.parentRefs[0].name` / `.namespace` |
| `hostnames` | `spec.hostnames` |
| `rules[].matches[].service` | `spec.rules[].matches[].method.service` |
| `rules[].matches[].method` | `spec.rules[].matches[].method.method` |
| `rules[].matches[].headers` | `spec.rules[].matches[].headers` |
| `rules[].backendPort` | `spec.rules[].backendRefs[0].port` |
| `component.metadata.name` | `spec.rules[].backendRefs[0].name` |

**TCPRoute mapping** (`#TcpRouteTrait` → `gateway.networking.k8s.io/v1alpha2 TCPRoute`):

| OPM field | Gateway API field |
|---|---|
| `gatewayRef.name` / `.namespace` | `spec.parentRefs[0].name` / `.namespace` |
| `rules[].backendPort` | `spec.rules[].backendRefs[0].port` |
| `component.metadata.name` | `spec.rules[].backendRefs[0].name` |

### D4: Transformer metadata conventions

Each new transformer follows the existing patterns:

```text
apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
name:        "<protocol>-route-transformer"  (e.g., "http-route-transformer")
labels:
  "core.opmodel.dev/trait-type":    "network"
  "core.opmodel.dev/resource-type": "<resource>"  (e.g., "httproute")
```

### D5: Gateway API version targeting

- HTTPRoute and GRPCRoute → `gateway.networking.k8s.io/v1` (GA since Gateway API v1.0.0 / v1.2.0 respectively)
- TCPRoute → `gateway.networking.k8s.io/v1alpha2` (still alpha)

## Risks / Trade-offs

- **[Breaking change for Ingress users]** → Users who relied on Ingress without explicitly setting `ingressClassName` will stop getting Ingress output. **Mitigation**: The project is under heavy development with the "APIs may change" caveat. Users can add `ingressClassName` to restore Ingress behavior. Gateway API HTTPRoute is always produced as a replacement.

- **[Hand-written types may drift from upstream]** → Gateway API CUE types are manually maintained and could become stale. **Mitigation**: Types are scoped to the fields OPM actually uses (not the full API surface). A comment documents the upstream version targeted. Future work can add a `cue.dev/x/sigs.k8s.io/gateway-api` dependency when one becomes available.

- **[TCPRoute is alpha]** → The `v1alpha2` API could change. **Mitigation**: TCPRoute is isolated in its own file and clearly labeled alpha. The OPM `#TcpRouteSchema` abstracts over the wire format.

- **[No Gateway/GatewayClass management]** → The transformers produce Route resources but not the Gateway itself. Users must ensure a Gateway exists in their cluster. **Mitigation**: This is intentional (Non-Goal). Gateway is a cluster-level resource managed by platform teams, not application definitions.

## Open Questions

- None blocking implementation. All decisions are resolved.
