---
status: not-started
phase: 1
updated: 2026-03-22
---

# Gateway API Extension Module

## Goal

Create a standalone CUE module under `catalog/v1alpha2/gateway_api/` that provides type-safe CUE definitions for all Kubernetes Gateway API resources (GA and experimental), imported from the official CRDs and refined with explicit constraints.

---

## Context & Decisions

| Decision | Rationale | Source |
|----------|-----------|--------|
| Adopt timoni-generated names (Option B) | No re-export mapping layer; no existing consumers to migrate since all transformers are being written fresh | Session decision 2026-03-22 |
| Gateway API types live in `opm` module, not `gateway_api` module | Transformers in `opm/providers/kubernetes/` need direct access to K8s types; `gateway_api` module depends on `opm`, not vice-versa | `opm/cue.mod/module.cue`, `catalog/v1alpha2/PLAN.md:Context` |

---

## Research Reference

This document captures all research gathered before implementation. Refer to it when making implementation decisions.

---

## Resource Inventory

### Standard Channel (GA) — `gateway.networking.k8s.io/v1`

These resources are stable and included in the standard install manifest.

| Resource | API Version | Description |
|---|---|---|
| `GatewayClass` | `v1` | Defines a class of Gateways managed by a specific controller |
| `Gateway` | `v1` | Instantiates a load balancer; Istio auto-provisions a Deployment + Service per Gateway |
| `HTTPRoute` | `v1` | Routes HTTP/HTTPS traffic to backends; the primary route type |
| `GRPCRoute` | `v1` | Routes gRPC traffic; graduated to GA in v1.1.0 |
| `TLSRoute` | `v1` | Routes TLS traffic by SNI hostname; graduated to GA in v1.5.0 |
| `ReferenceGrant` | `v1` | Permits cross-namespace references between route and backend resources |
| `BackendTLSPolicy` | `v1` | Configures TLS origination from a Gateway to a backend Service |
| `ListenerSet` | `v1` | Allows application teams to add listeners to a shared Gateway without owning it; new in v1.5.0 |

### Experimental Channel — additional resources

These resources are included in the experimental install manifest alongside all standard channel resources.

| Resource | API Version | Channel | Description |
|---|---|---|---|
| `TCPRoute` | `v1alpha2` | Experimental | Routes raw TCP connections; no L7 awareness |
| `UDPRoute` | `v1alpha2` | Experimental | Routes UDP traffic; rarely used in practice |
| `BackendTrafficPolicy` | `v1alpha2` | Experimental | Configures backend traffic policies (timeouts, retries, connection limits) for Services |

---

## CRD Source

| Property | Value |
|---|---|
| Version | v1.5.1 |
| Channel | experimental (superset of standard) |
| Standard install URL | `https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml` |
| Experimental install URL | `https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml` |
| Release notes | `https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.1` |

The experimental manifest is a strict superset of the standard manifest — it contains all GA resources plus the alpha resources. Use the experimental manifest to cover the full resource set in a single download.

**Important:** The experimental CRDs exceed the annotation size limit for standard `kubectl apply`. Apply them with `kubectl apply --server-side` on the target cluster.

---

## CRD Import Methodology

**Update 2026-03-22:** `timoni mod vendor crd` has replaced `cue import` as the chosen tool. It produces named sub-types, proper constraints, and pinned apiVersion/kind values automatically. The `cue import` notes below are retained for historical reference only.

No official CUE module exists for Gateway API at `registry.cue.works`. The types must be imported from the CRD YAML and then manually refined.

### Import command

```bash
cd catalog/v1alpha2/gateway_api
cue import -p gatewayapi -f --list crds/experimental-install.yaml
```

### What `cue import` produces

The importer outputs bare CUE structs. It does **not** produce:
- `#Definition` patterns — types come out as plain values, not schema definitions
- CUE constraints — no enum validation, no port range checks, no required field markers
- Comments — no documentation prose in the output

Manual refinement is required before the types can be used in OPM transformers. The import output is the starting point, not the finished product.

### Known limitation: `x-kubernetes-*` extensions

Kubernetes CRDs use non-standard OpenAPI extensions such as `x-kubernetes-int-or-string`, `x-kubernetes-preserve-unknown-fields`, and `x-kubernetes-validations` (CEL rules). These fields are not understood by standard OpenAPI importers. Using `cue import openapi` mode may fail or produce incorrect output because of these extensions.

Use plain YAML import mode (`cue import ... crds/experimental-install.yaml`) rather than OpenAPI mode. The plain import produces a structurally faithful representation without attempting to interpret the schema extensions.

### Refinement steps after import

After running `cue import`, apply the following manually:

1. Convert plain value definitions to `#Definition` patterns using `#` prefix
2. Constrain `apiVersion` to exact string values (e.g., `"gateway.networking.k8s.io/v1"`)
3. Constrain `kind` to exact string values (e.g., `"Gateway"`)
4. Add enum constraints for `protocol` fields: `"HTTP" | "HTTPS" | "TLS" | "TCP" | "UDP"`
5. Add port range constraints: `uint & >=1 & <=65535`
6. Mark required fields with `!` suffix
7. Mark optional fields with `?` suffix
8. Organize into files by API version:
   - `gateway_api/v1/types.cue` — all `v1` resources
   - `gateway_api/v1alpha2/types.cue` — all `v1alpha2` resources

---

## Key Resource Shapes

### Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: example
  namespace: istio-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod   # triggers auto-certificate
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      port: 80
      protocol: HTTP
    - name: https
      hostname: example.com
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - name: example-com-tls
            kind: Secret
      allowedRoutes:
        namespaces:
          from: Same
```

Key fields for OPM schema mapping:

| Gateway field | OPM schema field | Notes |
|---|---|---|
| `spec.gatewayClassName` | `#GatewaySchema.gatewayClassName` | Default: `"istio"` |
| `spec.listeners` | `#GatewaySchema.listeners` | Array of `#GatewayListenerSchema` |
| `spec.addresses` | `#GatewaySchema.addresses` | Optional; MetalLB assigns automatically when omitted |
| `spec.infrastructure` | `#GatewaySchema.infrastructure` | Optional; used for Istio `parametersRef` ConfigMap |
| `metadata.annotations` | `#GatewaySchema.issuerRef` | cert-manager annotation generated by transformer |

### HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example
  namespace: app-namespace
spec:
  parentRefs:
    - name: example-gateway
      namespace: istio-ingress
  hostnames:
    - example.com
  rules:
    - matches:
        - path:
            type: Prefix
            value: /api
      backendRefs:
        - name: my-service
          port: 8080
```

Key fields:

| HTTPRoute field | OPM source | Notes |
|---|---|---|
| `spec.parentRefs` | `#HttpRouteSchema.gatewayRef` | Transformer maps `gatewayRef` to `parentRefs` |
| `spec.hostnames` | `#HttpRouteSchema.hostnames` | Already in schema |
| `spec.rules[].matches` | `#HttpRouteSchema.rules[].matches` | Already in schema |
| `spec.rules[].backendRefs[].name` | Context (derived from component name) | Transformer derives service name |
| `spec.rules[].backendRefs[].port` | `#HttpRouteSchema.rules[].backendPort` | Already in schema |

### TLSRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: TLSRoute
metadata:
  name: example
  namespace: app-namespace
spec:
  parentRefs:
    - name: example-gateway
      namespace: istio-ingress
  hostnames:
    - example.com
  rules:
    - backendRefs:
        - name: my-service
          port: 8443
```

TLSRoute operates at L4 — it routes by SNI hostname without terminating TLS. The backend receives the raw TLS stream.

### TCPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: example
  namespace: app-namespace
spec:
  parentRefs:
    - name: example-gateway
      namespace: istio-ingress
  rules:
    - backendRefs:
        - name: my-service
          port: 5432
```

TCPRoute has no L7 awareness — no hostname matching, no header matching. It routes all traffic on the matched listener port to the backend.

### GatewayClass

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: my-gateway-class
spec:
  controllerName: example.com/gateway-controller
  description: "Custom gateway class for my controller"
  parametersRef:
    group: example.com
    kind: Config
    name: my-gateway-class-config
    namespace: my-namespace
```

Key fields for OPM schema mapping:

| GatewayClass field | OPM schema field | Notes |
|---|---|---|
| `spec.controllerName` | `#GatewayClassSchema.controllerName` | Required; identifies the controller that manages this class |
| `spec.description` | `#GatewayClassSchema.description` | Optional; human-readable description |
| `spec.parametersRef` | `#GatewayClassSchema.parametersRef` | Optional; controller-specific configuration reference |

Istio auto-creates `istio`, `istio-remote`, and `istio-waypoint` GatewayClasses on install. The OPM `#GatewayClassResource` is for deploying **custom** GatewayClass instances — for example, when operating a secondary Gateway API controller alongside Istio or in clusters where GatewayClasses must be explicitly managed.

### BackendTrafficPolicy

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: BackendTrafficPolicy
metadata:
  name: example
  namespace: app-namespace
spec:
  targetRef:
    group: ""
    kind: Service
    name: my-service
  sessionPersistence:
    sessionName: my-session
    type: Cookie
    cookieConfig:
      lifetimeType: Session
  retry:
    attempts: 3
    backoff: 1s
```

Key fields for OPM schema mapping:

| BackendTrafficPolicy field | OPM schema field | Notes |
|---|---|---|
| `spec.targetRef` | `#BackendTrafficPolicySchema.targetRef` | Required; references the Service to apply the policy to |
| `spec.sessionPersistence` | `#BackendTrafficPolicySchema.sessionPersistence` | Optional; configures sticky sessions (Cookie or Header-based) |
| `spec.retry` | `#BackendTrafficPolicySchema.retry` | Optional; configures retry attempts, backoff, and retry-on conditions |

BackendTrafficPolicy is an experimental resource in Gateway API v1alpha2. It applies backend traffic management at the Service level — not the route level. This makes it suitable for OPM components that need session affinity or retry logic regardless of which route sent traffic to the backend.

---

## Istio Integration

The cluster runs Istio v1.28.5 in ambient mode (ztunnel + istio-cni).

### GatewayClasses auto-created by Istio

| GatewayClass | Controller | Purpose |
|---|---|---|
| `istio` | `istio.io/gateway-controller` | Standard ingress gateway |
| `istio-remote` | `istio.io/gateway-controller` | Cross-cluster routing |
| `istio-waypoint` | `istio.io/gateway-controller` | Ambient mode L7 waypoint proxy |

All three are `Accepted: True` on the `admin@gon1-nas2` cluster.

### What Istio does when a Gateway resource is created

Istio's gateway deployment controller (`PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER=true`, enabled by default since v1.22) automatically provisions:

1. A Kubernetes `Deployment` running the Envoy proxy, named after the Gateway
2. A `LoadBalancer` Service exposing the Gateway listeners, named after the Gateway

These resources are created in the same namespace as the `Gateway` resource. No manual Deployment or Service definition is required in the OPM module.

### Ambient mode considerations

Gateway namespaces do not require `istio-injection: enabled` labels in ambient mode. The ztunnel component handles L4 traffic transparently. Authelia, configured as a mesh extension, applies auth policies to all Gateways automatically.

### Infrastructure customisation via `parametersRef`

Istio supports an optional `spec.infrastructure.parametersRef` field that points to a ConfigMap in the same namespace. This ConfigMap can override the auto-provisioned Deployment and Service settings:

```yaml
spec:
  infrastructure:
    parametersRef:
      group: ""
      kind: ConfigMap
      name: gateway-params
```

The ConfigMap contains a JSON payload:

```json
{
  "hpaSpec": { "minReplicas": 2, "maxReplicas": 5 },
  "service": { "loadBalancerIP": "10.10.0.180" }
}
```

The OPM `#GatewaySchema.infrastructure` field maps to this mechanism.

---

## cert-manager Gateway API Integration

cert-manager v1.15+ supports automatic Certificate provisioning from Gateway resources without requiring a feature flag.

### How it works

1. Add a cert-manager annotation to the Gateway resource
2. cert-manager watches for Gateway resources with these annotations
3. For each TLS listener with `mode: Terminate` and a `certificateRefs` entry, cert-manager creates a `Certificate` resource automatically
4. The Certificate's `dnsNames` are populated from the listener's `hostname`
5. The resulting Secret is named after the `certificateRefs[].name` value

### Supported annotations

```yaml
# Required: reference the issuer (one of these)
cert-manager.io/issuer: my-issuer
cert-manager.io/cluster-issuer: letsencrypt-prod

# Optional: for out-of-tree issuers
cert-manager.io/issuer-kind: AWSPCAIssuer
cert-manager.io/issuer-group: awspca.cert-manager.io

# Optional: certificate customisation
cert-manager.io/duration: 2160h
cert-manager.io/renew-before: 360h
cert-manager.io/private-key-algorithm: RSA
cert-manager.io/private-key-size: "2048"
```

### Listener requirements for auto-provisioning

A listener triggers automatic Certificate creation only if ALL of these conditions are met:

- `hostname` is set (not empty)
- `protocol` is `HTTPS` (not `HTTP`, `TCP`, or `TLS`)
- `tls.mode` is `Terminate` (not `Passthrough`)
- `tls.certificateRefs` contains at least one entry with a named Secret

### OPM transformer responsibility

The `#GatewayTransformer` is responsible for mapping the OPM-level `issuerRef` field to the correct cert-manager annotation on the output Gateway manifest. It should:

- Emit `cert-manager.io/cluster-issuer` when `issuerRef.kind == "ClusterIssuer"` or when `issuerRef.kind` is unset
- Emit `cert-manager.io/issuer` when `issuerRef.kind == "Issuer"`

---

## Module Structure

```text
gateway_api/
├── cue.mod/
│   └── module.cue          # CUE module: opmodel.dev/gateway-api@v1
├── crds/
│   └── experimental-install.yaml   # Downloaded CRD YAML (not imported, kept for reference)
├── v1/
│   └── types.cue           # GA resource type definitions
├── v1alpha2/
│   └── types.cue           # Experimental resource type definitions
├── version.yml             # CRD version tracking
├── PLAN.md                 # This document
└── README.md               # Brief module overview
```

---

## version.yml Format

```yaml
name: gateway-api
version: v1.5.1
channel: experimental
source: https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml
downloaded: 2026-03-22
notes: >
  Experimental channel is a superset of the standard channel.
  Includes all GA resources (v1) plus TCPRoute and UDPRoute (v1alpha2).
  Apply to cluster with kubectl apply --server-side due to CRD annotation size.
```

---

## Implementation Tasks

- [ ] **1.1 Create `cue.mod/module.cue`** ← CURRENT
  - Module path: `opmodel.dev/gateway-api@v1`
  - Language: `v0.15.0` (match `opm/cue.mod/module.cue`)

- [ ] 1.2 Download experimental CRDs
  - `curl -L -o crds/experimental-install.yaml https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml`
  - Create `version.yml` with format shown above

- [ ] 1.3 Run `timoni mod vendor crd`
  - `timoni mod vendor crd` against the downloaded experimental CRD YAML
  - Produces named sub-types with proper constraints, pinned apiVersion/kind
  - Output organized into `v1/` (GA) and `v1alpha2/` (experimental)
  - Adopt generated names directly (Option B) — no re-export mapping layer

- [ ] 1.4 Type validation tests
  - For each defined type, verify `cue vet` accepts a minimal valid instance
  - Verify `apiVersion` and `kind` constraints reject wrong values
  - Verify port range constraints reject out-of-range values

- [ ] 1.5 Cross-module import test
  - Create a temporary CUE file that imports `opmodel.dev/gateway-api/v1` and `opmodel.dev/gateway-api/v1alpha2`
  - Verify all exported `#` definitions are importable and usable as output type constraints
  - Delete the temporary file after verification

- [ ] 1.6 Validate
  - `cue vet ./...` from this directory
  - Confirm zero errors across all type files

---

## Notes

- 2026-03-22: Option B selected — timoni-generated names are adopted directly. When running `timoni mod vendor crd`, record exact generated type names here (e.g., what `#HTTPRoute` becomes) before writing any transformers.

---

## Links

- [Gateway API specification](https://gateway-api.sigs.k8s.io/)
- [Gateway API v1.5.0 release notes](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.0)
- [Gateway API v1.5.1 release](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.1)
- [Istio Gateway API task guide](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/)
- [Istio ambient mode](https://istio.io/latest/docs/ambient/)
- [cert-manager Gateway API integration](https://cert-manager.io/docs/usage/gateway/)
- [CUE import CLI reference](https://cuelang.org/docs/reference/cli/cue-import/)
