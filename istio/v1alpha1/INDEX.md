# v1alpha1 — Definition Index

CUE module: `opmodel.dev/istio/v1alpha1@v1`

---

## Project Structure

```
+-- crds/
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- extension/
|   +-- network/
|   +-- observability/
|   +-- security/
+-- schemas/
    +-- istio/
        +-- extensions.istio.io/
        |   +-- wasmplugin/
        |       +-- v1alpha1/
        +-- networking.istio.io/
        |   +-- destinationrule/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   |   +-- v1beta1/
        |   +-- envoyfilter/
        |   |   +-- v1alpha3/
        |   +-- gateway/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   |   +-- v1beta1/
        |   +-- proxyconfig/
        |   |   +-- v1beta1/
        |   +-- serviceentry/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   |   +-- v1beta1/
        |   +-- sidecar/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   |   +-- v1beta1/
        |   +-- virtualservice/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   |   +-- v1beta1/
        |   +-- workloadentry/
        |   |   +-- v1/
        |   |   +-- v1alpha3/
        |   |   +-- v1beta1/
        |   +-- workloadgroup/
        |       +-- v1/
        |       +-- v1alpha3/
        |       +-- v1beta1/
        +-- security.istio.io/
        |   +-- authorizationpolicy/
        |   |   +-- v1/
        |   |   +-- v1beta1/
        |   +-- peerauthentication/
        |   |   +-- v1/
        |   |   +-- v1beta1/
        |   +-- requestauthentication/
        |       +-- v1/
        |       +-- v1beta1/
        +-- telemetry.istio.io/
            +-- telemetry/
                +-- v1/
                +-- v1alpha1/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | IstioKubernetesProvider transforms Istio components to Kubernetes native CRs |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#AuthorizationPolicyTransformer` | `providers/kubernetes/transformers/authorization_policy_transformer.cue` |  |
| `#DestinationRuleTransformer` | `providers/kubernetes/transformers/destination_rule_transformer.cue` |  |
| `#EnvoyFilterTransformer` | `providers/kubernetes/transformers/envoy_filter_transformer.cue` |  |
| `#IstioGatewayTransformer` | `providers/kubernetes/transformers/istio_gateway_transformer.cue` |  |
| `#PeerAuthenticationTransformer` | `providers/kubernetes/transformers/peer_authentication_transformer.cue` |  |
| `#ProxyConfigTransformer` | `providers/kubernetes/transformers/proxy_config_transformer.cue` |  |
| `#RequestAuthenticationTransformer` | `providers/kubernetes/transformers/request_authentication_transformer.cue` |  |
| `#ServiceEntryTransformer` | `providers/kubernetes/transformers/service_entry_transformer.cue` |  |
| `#SidecarTransformer` | `providers/kubernetes/transformers/sidecar_transformer.cue` |  |
| `#TelemetryTransformer` | `providers/kubernetes/transformers/telemetry_transformer.cue` |  |
| `#VirtualServiceTransformer` | `providers/kubernetes/transformers/virtual_service_transformer.cue` | #VirtualServiceTransformer passes native Istio VirtualService resources through with OPM context applied (name prefix, namespace, labels) |
| `#WasmPluginTransformer` | `providers/kubernetes/transformers/wasm_plugin_transformer.cue` |  |
| `#WorkloadEntryTransformer` | `providers/kubernetes/transformers/workload_entry_transformer.cue` |  |
| `#WorkloadGroupTransformer` | `providers/kubernetes/transformers/workload_group_transformer.cue` |  |

---

## Resources

### extension

| Definition | File | Description |
|---|---|---|
| `#WasmPlugin` | `resources/extension/wasm_plugin.cue` |  |
| `#WasmPluginDefaults` | `resources/extension/wasm_plugin.cue` |  |
| `#WasmPluginResource` | `resources/extension/wasm_plugin.cue` |  |

### network

| Definition | File | Description |
|---|---|---|
| `#DestinationRule` | `resources/network/destination_rule.cue` |  |
| `#DestinationRuleDefaults` | `resources/network/destination_rule.cue` |  |
| `#DestinationRuleResource` | `resources/network/destination_rule.cue` |  |
| `#EnvoyFilter` | `resources/network/envoy_filter.cue` |  |
| `#EnvoyFilterDefaults` | `resources/network/envoy_filter.cue` |  |
| `#EnvoyFilterResource` | `resources/network/envoy_filter.cue` |  |
| `#IstioGateway` | `resources/network/gateway.cue` |  |
| `#IstioGatewayDefaults` | `resources/network/gateway.cue` |  |
| `#IstioGatewayResource` | `resources/network/gateway.cue` |  |
| `#ProxyConfig` | `resources/network/proxy_config.cue` |  |
| `#ProxyConfigDefaults` | `resources/network/proxy_config.cue` |  |
| `#ProxyConfigResource` | `resources/network/proxy_config.cue` |  |
| `#ServiceEntry` | `resources/network/service_entry.cue` |  |
| `#ServiceEntryDefaults` | `resources/network/service_entry.cue` |  |
| `#ServiceEntryResource` | `resources/network/service_entry.cue` |  |
| `#Sidecar` | `resources/network/sidecar.cue` |  |
| `#SidecarDefaults` | `resources/network/sidecar.cue` |  |
| `#SidecarResource` | `resources/network/sidecar.cue` |  |
| `#VirtualService` | `resources/network/virtual_service.cue` |  |
| `#VirtualServiceDefaults` | `resources/network/virtual_service.cue` |  |
| `#VirtualServiceResource` | `resources/network/virtual_service.cue` |  |
| `#WorkloadEntry` | `resources/network/workload_entry.cue` |  |
| `#WorkloadEntryDefaults` | `resources/network/workload_entry.cue` |  |
| `#WorkloadEntryResource` | `resources/network/workload_entry.cue` |  |
| `#WorkloadGroup` | `resources/network/workload_group.cue` |  |
| `#WorkloadGroupDefaults` | `resources/network/workload_group.cue` |  |
| `#WorkloadGroupResource` | `resources/network/workload_group.cue` |  |

### observability

| Definition | File | Description |
|---|---|---|
| `#Telemetry` | `resources/observability/telemetry.cue` |  |
| `#TelemetryDefaults` | `resources/observability/telemetry.cue` |  |
| `#TelemetryResource` | `resources/observability/telemetry.cue` |  |

### security

| Definition | File | Description |
|---|---|---|
| `#AuthorizationPolicy` | `resources/security/authorization_policy.cue` |  |
| `#AuthorizationPolicyDefaults` | `resources/security/authorization_policy.cue` |  |
| `#AuthorizationPolicyResource` | `resources/security/authorization_policy.cue` |  |
| `#PeerAuthentication` | `resources/security/peer_authentication.cue` |  |
| `#PeerAuthenticationDefaults` | `resources/security/peer_authentication.cue` |  |
| `#PeerAuthenticationResource` | `resources/security/peer_authentication.cue` |  |
| `#RequestAuthentication` | `resources/security/request_authentication.cue` |  |
| `#RequestAuthenticationDefaults` | `resources/security/request_authentication.cue` |  |
| `#RequestAuthenticationResource` | `resources/security/request_authentication.cue` |  |

---

## Schemas

### istio/extensions.istio.io/wasmplugin/v1alpha1

| Definition | File | Description |
|---|---|---|
| `#WasmPlugin` | `schemas/istio/extensions.istio.io/wasmplugin/v1alpha1/types_gen.cue` |  |
| `#WasmPluginSpec` | `schemas/istio/extensions.istio.io/wasmplugin/v1alpha1/types_gen.cue` | Extend the functionality provided by the Istio proxy through WebAssembly filters |

### istio/networking.istio.io/destinationrule/v1

| Definition | File | Description |
|---|---|---|
| `#DestinationRule` | `schemas/istio/networking.istio.io/destinationrule/v1/types_gen.cue` |  |
| `#DestinationRuleSpec` | `schemas/istio/networking.istio.io/destinationrule/v1/types_gen.cue` | Configuration affecting load balancing, outlier detection, etc |

### istio/networking.istio.io/destinationrule/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#DestinationRule` | `schemas/istio/networking.istio.io/destinationrule/v1alpha3/types_gen.cue` |  |
| `#DestinationRuleSpec` | `schemas/istio/networking.istio.io/destinationrule/v1alpha3/types_gen.cue` | Configuration affecting load balancing, outlier detection, etc |

### istio/networking.istio.io/destinationrule/v1beta1

| Definition | File | Description |
|---|---|---|
| `#DestinationRule` | `schemas/istio/networking.istio.io/destinationrule/v1beta1/types_gen.cue` |  |
| `#DestinationRuleSpec` | `schemas/istio/networking.istio.io/destinationrule/v1beta1/types_gen.cue` | Configuration affecting load balancing, outlier detection, etc |

### istio/networking.istio.io/envoyfilter/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#EnvoyFilter` | `schemas/istio/networking.istio.io/envoyfilter/v1alpha3/types_gen.cue` |  |
| `#EnvoyFilterSpec` | `schemas/istio/networking.istio.io/envoyfilter/v1alpha3/types_gen.cue` | Customizing Envoy configuration generated by Istio |

### istio/networking.istio.io/gateway/v1

| Definition | File | Description |
|---|---|---|
| `#Gateway` | `schemas/istio/networking.istio.io/gateway/v1/types_gen.cue` |  |
| `#GatewaySpec` | `schemas/istio/networking.istio.io/gateway/v1/types_gen.cue` | Configuration affecting edge load balancer |

### istio/networking.istio.io/gateway/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#Gateway` | `schemas/istio/networking.istio.io/gateway/v1alpha3/types_gen.cue` |  |
| `#GatewaySpec` | `schemas/istio/networking.istio.io/gateway/v1alpha3/types_gen.cue` | Configuration affecting edge load balancer |

### istio/networking.istio.io/gateway/v1beta1

| Definition | File | Description |
|---|---|---|
| `#Gateway` | `schemas/istio/networking.istio.io/gateway/v1beta1/types_gen.cue` |  |
| `#GatewaySpec` | `schemas/istio/networking.istio.io/gateway/v1beta1/types_gen.cue` | Configuration affecting edge load balancer |

### istio/networking.istio.io/proxyconfig/v1beta1

| Definition | File | Description |
|---|---|---|
| `#ProxyConfig` | `schemas/istio/networking.istio.io/proxyconfig/v1beta1/types_gen.cue` |  |
| `#ProxyConfigSpec` | `schemas/istio/networking.istio.io/proxyconfig/v1beta1/types_gen.cue` | Provides configuration for individual workloads |

### istio/networking.istio.io/serviceentry/v1

| Definition | File | Description |
|---|---|---|
| `#ServiceEntry` | `schemas/istio/networking.istio.io/serviceentry/v1/types_gen.cue` |  |
| `#ServiceEntrySpec` | `schemas/istio/networking.istio.io/serviceentry/v1/types_gen.cue` | Configuration affecting service registry |

### istio/networking.istio.io/serviceentry/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#ServiceEntry` | `schemas/istio/networking.istio.io/serviceentry/v1alpha3/types_gen.cue` |  |
| `#ServiceEntrySpec` | `schemas/istio/networking.istio.io/serviceentry/v1alpha3/types_gen.cue` | Configuration affecting service registry |

### istio/networking.istio.io/serviceentry/v1beta1

| Definition | File | Description |
|---|---|---|
| `#ServiceEntry` | `schemas/istio/networking.istio.io/serviceentry/v1beta1/types_gen.cue` |  |
| `#ServiceEntrySpec` | `schemas/istio/networking.istio.io/serviceentry/v1beta1/types_gen.cue` | Configuration affecting service registry |

### istio/networking.istio.io/sidecar/v1

| Definition | File | Description |
|---|---|---|
| `#Sidecar` | `schemas/istio/networking.istio.io/sidecar/v1/types_gen.cue` |  |
| `#SidecarSpec` | `schemas/istio/networking.istio.io/sidecar/v1/types_gen.cue` | Configuration affecting network reachability of a sidecar |

### istio/networking.istio.io/sidecar/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#Sidecar` | `schemas/istio/networking.istio.io/sidecar/v1alpha3/types_gen.cue` |  |
| `#SidecarSpec` | `schemas/istio/networking.istio.io/sidecar/v1alpha3/types_gen.cue` | Configuration affecting network reachability of a sidecar |

### istio/networking.istio.io/sidecar/v1beta1

| Definition | File | Description |
|---|---|---|
| `#Sidecar` | `schemas/istio/networking.istio.io/sidecar/v1beta1/types_gen.cue` |  |
| `#SidecarSpec` | `schemas/istio/networking.istio.io/sidecar/v1beta1/types_gen.cue` | Configuration affecting network reachability of a sidecar |

### istio/networking.istio.io/virtualservice/v1

| Definition | File | Description |
|---|---|---|
| `#VirtualService` | `schemas/istio/networking.istio.io/virtualservice/v1/types_gen.cue` |  |
| `#VirtualServiceSpec` | `schemas/istio/networking.istio.io/virtualservice/v1/types_gen.cue` | Configuration affecting label/content routing, sni routing, etc |

### istio/networking.istio.io/virtualservice/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#VirtualService` | `schemas/istio/networking.istio.io/virtualservice/v1alpha3/types_gen.cue` |  |
| `#VirtualServiceSpec` | `schemas/istio/networking.istio.io/virtualservice/v1alpha3/types_gen.cue` | Configuration affecting label/content routing, sni routing, etc |

### istio/networking.istio.io/virtualservice/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VirtualService` | `schemas/istio/networking.istio.io/virtualservice/v1beta1/types_gen.cue` |  |
| `#VirtualServiceSpec` | `schemas/istio/networking.istio.io/virtualservice/v1beta1/types_gen.cue` | Configuration affecting label/content routing, sni routing, etc |

### istio/networking.istio.io/workloadentry/v1

| Definition | File | Description |
|---|---|---|
| `#WorkloadEntry` | `schemas/istio/networking.istio.io/workloadentry/v1/types_gen.cue` |  |
| `#WorkloadEntrySpec` | `schemas/istio/networking.istio.io/workloadentry/v1/types_gen.cue` | Configuration affecting VMs onboarded into the mesh |

### istio/networking.istio.io/workloadentry/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#WorkloadEntry` | `schemas/istio/networking.istio.io/workloadentry/v1alpha3/types_gen.cue` |  |
| `#WorkloadEntrySpec` | `schemas/istio/networking.istio.io/workloadentry/v1alpha3/types_gen.cue` | Configuration affecting VMs onboarded into the mesh |

### istio/networking.istio.io/workloadentry/v1beta1

| Definition | File | Description |
|---|---|---|
| `#WorkloadEntry` | `schemas/istio/networking.istio.io/workloadentry/v1beta1/types_gen.cue` |  |
| `#WorkloadEntrySpec` | `schemas/istio/networking.istio.io/workloadentry/v1beta1/types_gen.cue` | Configuration affecting VMs onboarded into the mesh |

### istio/networking.istio.io/workloadgroup/v1

| Definition | File | Description |
|---|---|---|
| `#WorkloadGroup` | `schemas/istio/networking.istio.io/workloadgroup/v1/types_gen.cue` |  |
| `#WorkloadGroupSpec` | `schemas/istio/networking.istio.io/workloadgroup/v1/types_gen.cue` | Describes a collection of workload instances |

### istio/networking.istio.io/workloadgroup/v1alpha3

| Definition | File | Description |
|---|---|---|
| `#WorkloadGroup` | `schemas/istio/networking.istio.io/workloadgroup/v1alpha3/types_gen.cue` |  |
| `#WorkloadGroupSpec` | `schemas/istio/networking.istio.io/workloadgroup/v1alpha3/types_gen.cue` | Describes a collection of workload instances |

### istio/networking.istio.io/workloadgroup/v1beta1

| Definition | File | Description |
|---|---|---|
| `#WorkloadGroup` | `schemas/istio/networking.istio.io/workloadgroup/v1beta1/types_gen.cue` |  |
| `#WorkloadGroupSpec` | `schemas/istio/networking.istio.io/workloadgroup/v1beta1/types_gen.cue` | Describes a collection of workload instances |

### istio/security.istio.io/authorizationpolicy/v1

| Definition | File | Description |
|---|---|---|
| `#AuthorizationPolicy` | `schemas/istio/security.istio.io/authorizationpolicy/v1/types_gen.cue` |  |
| `#AuthorizationPolicySpec` | `schemas/istio/security.istio.io/authorizationpolicy/v1/types_gen.cue` | Configuration for access control on workloads |

### istio/security.istio.io/authorizationpolicy/v1beta1

| Definition | File | Description |
|---|---|---|
| `#AuthorizationPolicy` | `schemas/istio/security.istio.io/authorizationpolicy/v1beta1/types_gen.cue` |  |
| `#AuthorizationPolicySpec` | `schemas/istio/security.istio.io/authorizationpolicy/v1beta1/types_gen.cue` | Configuration for access control on workloads |

### istio/security.istio.io/peerauthentication/v1

| Definition | File | Description |
|---|---|---|
| `#PeerAuthentication` | `schemas/istio/security.istio.io/peerauthentication/v1/types_gen.cue` |  |
| `#PeerAuthenticationSpec` | `schemas/istio/security.istio.io/peerauthentication/v1/types_gen.cue` | Peer authentication configuration for workloads |

### istio/security.istio.io/peerauthentication/v1beta1

| Definition | File | Description |
|---|---|---|
| `#PeerAuthentication` | `schemas/istio/security.istio.io/peerauthentication/v1beta1/types_gen.cue` |  |
| `#PeerAuthenticationSpec` | `schemas/istio/security.istio.io/peerauthentication/v1beta1/types_gen.cue` | Peer authentication configuration for workloads |

### istio/security.istio.io/requestauthentication/v1

| Definition | File | Description |
|---|---|---|
| `#RequestAuthentication` | `schemas/istio/security.istio.io/requestauthentication/v1/types_gen.cue` |  |
| `#RequestAuthenticationSpec` | `schemas/istio/security.istio.io/requestauthentication/v1/types_gen.cue` | Request authentication configuration for workloads |

### istio/security.istio.io/requestauthentication/v1beta1

| Definition | File | Description |
|---|---|---|
| `#RequestAuthentication` | `schemas/istio/security.istio.io/requestauthentication/v1beta1/types_gen.cue` |  |
| `#RequestAuthenticationSpec` | `schemas/istio/security.istio.io/requestauthentication/v1beta1/types_gen.cue` | Request authentication configuration for workloads |

### istio/telemetry.istio.io/telemetry/v1

| Definition | File | Description |
|---|---|---|
| `#Telemetry` | `schemas/istio/telemetry.istio.io/telemetry/v1/types_gen.cue` |  |
| `#TelemetrySpec` | `schemas/istio/telemetry.istio.io/telemetry/v1/types_gen.cue` | Telemetry configuration for workloads |

### istio/telemetry.istio.io/telemetry/v1alpha1

| Definition | File | Description |
|---|---|---|
| `#Telemetry` | `schemas/istio/telemetry.istio.io/telemetry/v1alpha1/types_gen.cue` |  |
| `#TelemetrySpec` | `schemas/istio/telemetry.istio.io/telemetry/v1alpha1/types_gen.cue` | Telemetry configuration for workloads |

---

