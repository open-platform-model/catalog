# v1alpha1 — Definition Index

CUE module: `opmodel.dev/gateway_api/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- network/
+-- schemas/
    +-- gateway/
        +-- gateway.networking.k8s.io/
        |   +-- backendtlspolicy/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   +-- gateway/
        |   |   +-- v1/
        |   |   +-- v1beta1/
        |   +-- gatewayclass/
        |   |   +-- v1/
        |   |   +-- v1beta1/
        |   +-- grpcroute/
        |   |   +-- v1/
        |   +-- httproute/
        |   |   +-- v1/
        |   |   +-- v1beta1/
        |   +-- listenerset/
        |   |   +-- v1/
        |   +-- referencegrant/
        |   |   +-- v1/
        |   |   +-- v1beta1/
        |   +-- tcproute/
        |   |   +-- v1alpha2/
        |   +-- tlsroute/
        |   |   +-- v1/
        |   |   +-- v1alpha2/
        |   |   +-- v1alpha3/
        |   +-- udproute/
        |       +-- v1alpha2/
        +-- gateway.networking.x-k8s.io/
            +-- xbackendtrafficpolicy/
            |   +-- v1alpha1/
            +-- xmesh/
                +-- v1alpha1/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | GatewayAPIKubernetesProvider transforms Gateway API components to Kubernetes native resources |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#BackendTrafficPolicyTransformer` | `providers/kubernetes/transformers/backend_traffic_policy_transformer.cue` | #BackendTrafficPolicyTransformer passes native Gateway API BackendTrafficPolicy resources through with OPM context applied (name prefix, namespace, labels) |
| `#GatewayClassTransformer` | `providers/kubernetes/transformers/gateway_class_transformer.cue` | #GatewayClassTransformer passes native Gateway API GatewayClass resources through with OPM context applied (name prefix, labels) |
| `#GatewayTransformer` | `providers/kubernetes/transformers/gateway_transformer.cue` | #GatewayTransformer passes native Gateway API Gateway resources through with OPM context applied (name prefix, namespace, labels) |
| `#GrpcRouteTransformer` | `providers/kubernetes/transformers/grpc_route_transformer.cue` | #GrpcRouteTransformer passes native Gateway API GRPCRoute resources through with OPM context applied (name prefix, namespace, labels) |
| `#HttpRouteTransformer` | `providers/kubernetes/transformers/http_route_transformer.cue` | #HttpRouteTransformer passes native Gateway API HTTPRoute resources through with OPM context applied (name prefix, namespace, labels) |
| `#ReferenceGrantTransformer` | `providers/kubernetes/transformers/reference_grant_transformer.cue` | #ReferenceGrantTransformer passes native Gateway API ReferenceGrant resources through with OPM context applied (name prefix, namespace, labels) |
| `#TcpRouteTransformer` | `providers/kubernetes/transformers/tcp_route_transformer.cue` | #TcpRouteTransformer passes native Gateway API TCPRoute resources through with OPM context applied (name prefix, namespace, labels) |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |
| `#TlsRouteTransformer` | `providers/kubernetes/transformers/tls_route_transformer.cue` | #TlsRouteTransformer passes native Gateway API TLSRoute resources through with OPM context applied (name prefix, namespace, labels) |

---

## Resources

### network

| Definition | File | Description |
|---|---|---|
| `#BackendTrafficPolicy` | `resources/network/backend_traffic_policy.cue` |  |
| `#BackendTrafficPolicyDefaults` | `resources/network/backend_traffic_policy.cue` |  |
| `#BackendTrafficPolicyResource` | `resources/network/backend_traffic_policy.cue` |  |
| `#GatewayClass` | `resources/network/gateway_class.cue` |  |
| `#GatewayClassDefaults` | `resources/network/gateway_class.cue` |  |
| `#GatewayClassResource` | `resources/network/gateway_class.cue` |  |
| `#Gateway` | `resources/network/gateway.cue` |  |
| `#GatewayDefaults` | `resources/network/gateway.cue` |  |
| `#GatewayResource` | `resources/network/gateway.cue` |  |
| `#GrpcRoute` | `resources/network/grpc_route.cue` |  |
| `#GrpcRouteDefaults` | `resources/network/grpc_route.cue` |  |
| `#GrpcRouteResource` | `resources/network/grpc_route.cue` |  |
| `#HttpRoute` | `resources/network/http_route.cue` |  |
| `#HttpRouteDefaults` | `resources/network/http_route.cue` |  |
| `#HttpRouteResource` | `resources/network/http_route.cue` |  |
| `#ReferenceGrant` | `resources/network/reference_grant.cue` |  |
| `#ReferenceGrantDefaults` | `resources/network/reference_grant.cue` |  |
| `#ReferenceGrantResource` | `resources/network/reference_grant.cue` |  |
| `#TcpRoute` | `resources/network/tcp_route.cue` |  |
| `#TcpRouteDefaults` | `resources/network/tcp_route.cue` |  |
| `#TcpRouteResource` | `resources/network/tcp_route.cue` |  |
| `#TlsRoute` | `resources/network/tls_route.cue` |  |
| `#TlsRouteDefaults` | `resources/network/tls_route.cue` |  |
| `#TlsRouteResource` | `resources/network/tls_route.cue` |  |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#BackendTrafficPolicySchema` | `schemas/network.cue` | #BackendTrafficPolicySchema accepts the full Gateway API BackendTrafficPolicy spec |
| `#GatewayClassSchema` | `schemas/network.cue` | #GatewayClassSchema accepts the full Gateway API GatewayClass spec |
| `#GatewaySchema` | `schemas/network.cue` | #GatewaySchema accepts the full Gateway API Gateway spec |
| `#GrpcRouteSchema` | `schemas/network.cue` | #GrpcRouteSchema accepts the full Gateway API GRPCRoute spec |
| `#HttpRouteSchema` | `schemas/network.cue` | #HttpRouteSchema accepts the full Gateway API HTTPRoute spec |
| `#ReferenceGrantSchema` | `schemas/network.cue` | #ReferenceGrantSchema accepts the full Gateway API ReferenceGrant spec |
| `#TcpRouteSchema` | `schemas/network.cue` | #TcpRouteSchema accepts the full Gateway API TCPRoute spec |
| `#TlsRouteSchema` | `schemas/network.cue` | #TlsRouteSchema accepts the full Gateway API TLSRoute spec |

### gateway/gateway.networking.k8s.io/backendtlspolicy/v1

| Definition | File | Description |
|---|---|---|
| `#BackendTLSPolicy` | `schemas/gateway/gateway.networking.k8s.io/backendtlspolicy/v1/types_gen.cue` | BackendTLSPolicy provides a way to configure how a Gateway connects to a Backend via TLS |
| `#BackendTLSPolicySpec` | `schemas/gateway/gateway.networking.k8s.io/backendtlspolicy/v1/types_gen.cue` | Spec defines the desired state of BackendTLSPolicy |

### gateway/gateway.networking.k8s.io/backendtlspolicy/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#BackendTLSPolicy` | `schemas/gateway/gateway.networking.k8s.io/backendtlspolicy/v1alpha3/types_gen.cue` | BackendTLSPolicy provides a way to configure how a Gateway connects to a Backend via TLS |
| `#BackendTLSPolicySpec` | `schemas/gateway/gateway.networking.k8s.io/backendtlspolicy/v1alpha3/types_gen.cue` | Spec defines the desired state of BackendTLSPolicy |

### gateway/gateway.networking.k8s.io/gatewayclass/v1

| Definition | File | Description |
|---|---|---|
| `#GatewayClass` | `schemas/gateway/gateway.networking.k8s.io/gatewayclass/v1/types_gen.cue` | GatewayClass describes a class of Gateways available to the user for creating Gateway resources |
| `#GatewayClassSpec` | `schemas/gateway/gateway.networking.k8s.io/gatewayclass/v1/types_gen.cue` | Spec defines the desired state of GatewayClass |

### gateway/gateway.networking.k8s.io/gatewayclass/v1beta1

| Definition | File | Description |
|---|---|---|
| `#GatewayClass` | `schemas/gateway/gateway.networking.k8s.io/gatewayclass/v1beta1/types_gen.cue` | GatewayClass describes a class of Gateways available to the user for creating Gateway resources |
| `#GatewayClassSpec` | `schemas/gateway/gateway.networking.k8s.io/gatewayclass/v1beta1/types_gen.cue` | Spec defines the desired state of GatewayClass |

### gateway/gateway.networking.k8s.io/gateway/v1

| Definition | File | Description |
|---|---|---|
| `#Gateway` | `schemas/gateway/gateway.networking.k8s.io/gateway/v1/types_gen.cue` | Gateway represents an instance of a service-traffic handling infrastructure by binding Listeners to a set of IP addresses |
| `#GatewaySpec` | `schemas/gateway/gateway.networking.k8s.io/gateway/v1/types_gen.cue` | Spec defines the desired state of Gateway |

### gateway/gateway.networking.k8s.io/gateway/v1beta1

| Definition | File | Description |
|---|---|---|
| `#Gateway` | `schemas/gateway/gateway.networking.k8s.io/gateway/v1beta1/types_gen.cue` | Gateway represents an instance of a service-traffic handling infrastructure by binding Listeners to a set of IP addresses |
| `#GatewaySpec` | `schemas/gateway/gateway.networking.k8s.io/gateway/v1beta1/types_gen.cue` | Spec defines the desired state of Gateway |

### gateway/gateway.networking.k8s.io/grpcroute/v1

| Definition | File | Description |
|---|---|---|
| `#GRPCRoute` | `schemas/gateway/gateway.networking.k8s.io/grpcroute/v1/types_gen.cue` | GRPCRoute provides a way to route gRPC requests |
| `#GRPCRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/grpcroute/v1/types_gen.cue` | Spec defines the desired state of GRPCRoute |

### gateway/gateway.networking.k8s.io/httproute/v1

| Definition | File | Description |
|---|---|---|
| `#HTTPRoute` | `schemas/gateway/gateway.networking.k8s.io/httproute/v1/types_gen.cue` | HTTPRoute provides a way to route HTTP requests |
| `#HTTPRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/httproute/v1/types_gen.cue` | Spec defines the desired state of HTTPRoute |

### gateway/gateway.networking.k8s.io/httproute/v1beta1

| Definition | File | Description |
|---|---|---|
| `#HTTPRoute` | `schemas/gateway/gateway.networking.k8s.io/httproute/v1beta1/types_gen.cue` | HTTPRoute provides a way to route HTTP requests |
| `#HTTPRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/httproute/v1beta1/types_gen.cue` | Spec defines the desired state of HTTPRoute |

### gateway/gateway.networking.k8s.io/listenerset/v1

| Definition | File | Description |
|---|---|---|
| `#ListenerSet` | `schemas/gateway/gateway.networking.k8s.io/listenerset/v1/types_gen.cue` | ListenerSet defines a set of additional listeners to attach to an existing Gateway |
| `#ListenerSetSpec` | `schemas/gateway/gateway.networking.k8s.io/listenerset/v1/types_gen.cue` | Spec defines the desired state of ListenerSet |

### gateway/gateway.networking.k8s.io/referencegrant/v1

| Definition | File | Description |
|---|---|---|
| `#ReferenceGrant` | `schemas/gateway/gateway.networking.k8s.io/referencegrant/v1/types_gen.cue` | ReferenceGrant identifies kinds of resources in other namespaces that are trusted to reference the specified kinds of resources in the same namespace as the policy |
| `#ReferenceGrantSpec` | `schemas/gateway/gateway.networking.k8s.io/referencegrant/v1/types_gen.cue` | Spec defines the desired state of ReferenceGrant |

### gateway/gateway.networking.k8s.io/referencegrant/v1beta1

| Definition | File | Description |
|---|---|---|
| `#ReferenceGrant` | `schemas/gateway/gateway.networking.k8s.io/referencegrant/v1beta1/types_gen.cue` | ReferenceGrant identifies kinds of resources in other namespaces that are trusted to reference the specified kinds of resources in the same namespace as the policy |
| `#ReferenceGrantSpec` | `schemas/gateway/gateway.networking.k8s.io/referencegrant/v1beta1/types_gen.cue` | Spec defines the desired state of ReferenceGrant |

### gateway/gateway.networking.k8s.io/tcproute/v1alpha2

| Definition | File | Description |
|---|---|---|
| `#TCPRoute` | `schemas/gateway/gateway.networking.k8s.io/tcproute/v1alpha2/types_gen.cue` | TCPRoute provides a way to route TCP requests |
| `#TCPRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/tcproute/v1alpha2/types_gen.cue` | Spec defines the desired state of TCPRoute |

### gateway/gateway.networking.k8s.io/tlsroute/v1

| Definition | File | Description |
|---|---|---|
| `#TLSRoute` | `schemas/gateway/gateway.networking.k8s.io/tlsroute/v1/types_gen.cue` | The TLSRoute resource is similar to TCPRoute, but can be configured to match against TLS-specific metadata |
| `#TLSRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/tlsroute/v1/types_gen.cue` | Spec defines the desired state of TLSRoute |

### gateway/gateway.networking.k8s.io/tlsroute/v1alpha2

| Definition | File | Description |
|---|---|---|
| `#TLSRoute` | `schemas/gateway/gateway.networking.k8s.io/tlsroute/v1alpha2/types_gen.cue` | The TLSRoute resource is similar to TCPRoute, but can be configured to match against TLS-specific metadata |
| `#TLSRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/tlsroute/v1alpha2/types_gen.cue` | Spec defines the desired state of TLSRoute |

### gateway/gateway.networking.k8s.io/tlsroute/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#TLSRoute` | `schemas/gateway/gateway.networking.k8s.io/tlsroute/v1alpha3/types_gen.cue` | The TLSRoute resource is similar to TCPRoute, but can be configured to match against TLS-specific metadata |
| `#TLSRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/tlsroute/v1alpha3/types_gen.cue` | Spec defines the desired state of TLSRoute |

### gateway/gateway.networking.k8s.io/udproute/v1alpha2

| Definition | File | Description |
|---|---|---|
| `#UDPRoute` | `schemas/gateway/gateway.networking.k8s.io/udproute/v1alpha2/types_gen.cue` | UDPRoute provides a way to route UDP traffic |
| `#UDPRouteSpec` | `schemas/gateway/gateway.networking.k8s.io/udproute/v1alpha2/types_gen.cue` | Spec defines the desired state of UDPRoute |

### gateway/gateway.networking.x-k8s.io/xbackendtrafficpolicy/v1alpha1

| Definition | File | Description |
|---|---|---|
| `#XBackendTrafficPolicy` | `schemas/gateway/gateway.networking.x-k8s.io/xbackendtrafficpolicy/v1alpha1/types_gen.cue` | XBackendTrafficPolicy defines the configuration for how traffic to a target backend should be handled |
| `#XBackendTrafficPolicySpec` | `schemas/gateway/gateway.networking.x-k8s.io/xbackendtrafficpolicy/v1alpha1/types_gen.cue` | Spec defines the desired state of BackendTrafficPolicy |

### gateway/gateway.networking.x-k8s.io/xmesh/v1alpha1

| Definition | File | Description |
|---|---|---|
| `#XMesh` | `schemas/gateway/gateway.networking.x-k8s.io/xmesh/v1alpha1/types_gen.cue` | XMesh defines mesh-wide characteristics of a GAMMA-compliant service mesh |
| `#XMeshSpec` | `schemas/gateway/gateway.networking.x-k8s.io/xmesh/v1alpha1/types_gen.cue` | Spec defines the desired state of XMesh |

---

