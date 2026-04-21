# Gateway API Routing — Third Worked Example

This document walks Gateway API routing (HTTPRoute and siblings) through the same pattern as backup and TLS. It is the third data point for OQ-5 and closes the question of whether the pattern generalizes across commodities with different output cardinalities and inter-entity coupling.

## Scope

Five route kinds in Gateway API:

| Protocol | Route CR | Commonality |
| --- | --- | --- |
| HTTP | `HTTPRoute` | Path/method/header matching + rich filters |
| TLS passthrough / SNI | `TLSRoute` | SNI-only matching |
| gRPC | `GRPCRoute` | Service/method matching + HTTP-ish filters |
| TCP | `TCPRoute` | Port-based only (no content routing) |
| UDP | `UDPRoute` | Port-based only |

All five share the same Trait + Directive + PolicyTransformer skeleton. This document shows HTTPRoute in full and summarizes the siblings.

## Layer Split

| Layer | Belongs to | Examples |
| --- | --- | --- |
| Component-local | `#HTTPRouteTrait` | paths/methods/headers to match, backend port on *me*, per-rule filters, per-rule timeouts, per-component hostname override (rare) |
| Module-level | `#HTTPRoutePolicy` (Directive) | Gateway ref, listener section, hostnames, default filters, default timeouts |
| Platform-level | `#Platform.#ctx.platform.routing.gateways` | available Gateways with their listeners (port, protocol) |

**Hostname lives at the policy, not the trait.** Hostname is a module-level contract — "this module serves `strix.example.com`." Components declare only the paths they handle. A per-component hostname override remains possible as an escape hatch on the trait.

## File Layout

A single CUE package exports all five trait/directive pairs plus shared helpers:

```text
catalog/opm/v1alpha1/operations/routing/
├── common.cue               — shared #HTTPRouteFilter, #HeaderMatch, etc.
├── http_route_trait.cue     — #HTTPRouteTrait
├── http_route_directive.cue — #HTTPRoutePolicy
├── tls_route_trait.cue      — #TLSRouteTrait
├── tls_route_directive.cue  — #TLSRoutePolicy
├── grpc_route_trait.cue     — #GRPCRouteTrait
├── grpc_route_directive.cue — #GRPCRoutePolicy
├── tcp_route_trait.cue      — #TCPRouteTrait
├── tcp_route_directive.cue  — #TCPRoutePolicy
├── udp_route_trait.cue      — #UDPRouteTrait
└── udp_route_directive.cue  — #UDPRoutePolicy
```

Import path: `opmodel.dev/opm/v1alpha1/operations/routing@v1`. Single import fixes versions for all five.

## `#HTTPRouteTrait`

```cue
// catalog/opm/v1alpha1/operations/routing/http_route_trait.cue
package routing

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#HTTPRouteTrait: prim.#Trait & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/operations/routing"
        version:     "v1"
        name:        "http-route"
        description: "Declares HTTP routing rules this component handles"
        labels: {
            "trait.opmodel.dev/category": "networking"
        }
    }

    #spec: httpRoute: {
        rules!: [...close({
            matches?: [...close({
                path?: close({
                    type:  *"PathPrefix" | "Exact" | "RegularExpression"
                    value: string
                })
                method?: "GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "PATCH" | "OPTIONS" | "CONNECT" | "TRACE"
                headers?: [...close({
                    type:  *"Exact" | "RegularExpression"
                    name:  string
                    value: string
                })]
                queryParams?: [...close({
                    type:  *"Exact" | "RegularExpression"
                    name:  string
                    value: string
                })]
            })]

            // Port on this component's Service to receive matched traffic.
            backendPort!: int & >=1 & <=65535

            // Optional weight — meaningful only if multiple components share a match.
            weight?: int & >=0 & <=1000000

            // Per-rule filters. Prepended to policy-level defaultFilters at render time.
            filters?: [...#HTTPRouteFilter]

            // Per-rule timeouts — override policy defaults.
            timeouts?: close({
                request?:        string
                backendRequest?: string
            })
        })] & list.MinItems(1)

        // Escape hatch — component-local hostname override. Unified with policy.hostnames
        // at render time. Rare; most modules set hostnames only on the policy.
        hostnames?: [...string]
    }
}
```

`#HTTPRouteFilter` (in `common.cue`):

```cue
#HTTPRouteFilter: close({
    type: "RequestHeaderModifier" | "ResponseHeaderModifier" |
          "URLRewrite" | "RequestRedirect" | "RequestMirror"

    if type == "RequestHeaderModifier" {
        requestHeaderModifier: close({
            set?:    [...{name: string, value: string}]
            add?:    [...{name: string, value: string}]
            remove?: [...string]
        })
    }
    if type == "ResponseHeaderModifier" {
        responseHeaderModifier: close({
            set?:    [...{name: string, value: string}]
            add?:    [...{name: string, value: string}]
            remove?: [...string]
        })
    }
    if type == "URLRewrite" {
        urlRewrite: close({
            hostname?: string
            path?: close({
                type:                "ReplaceFullPath" | "ReplacePrefixMatch"
                replaceFullPath?:    string
                replacePrefixMatch?: string
            })
        })
    }
    if type == "RequestRedirect" {
        requestRedirect: close({
            scheme?:     "http" | "https"
            hostname?:   string
            port?:       int & >=1 & <=65535
            statusCode?: 301 | 302 | 303 | 307 | 308
            path?: close({
                type:                "ReplaceFullPath" | "ReplacePrefixMatch"
                replaceFullPath?:    string
                replacePrefixMatch?: string
            })
        })
    }
    if type == "RequestMirror" {
        requestMirror: close({
            backendRef: close({
                name:       string
                namespace?: string
                port:       int & >=1 & <=65535
            })
        })
    }
})
```

## `#HTTPRoutePolicy`

```cue
// catalog/opm/v1alpha1/operations/routing/http_route_directive.cue
package routing

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#HTTPRoutePolicy: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/operations/routing"
        version:     "v1"
        name:        "http-route"
        description: "Attaches components' HTTP routes to a Gateway listener under a shared hostname set"
        labels: {
            "directive.opmodel.dev/category": "networking"
        }
    }

    #spec: httpRoute: {
        // Attachment — named reference resolved via
        // #Platform.#ctx.platform.routing.gateways[gateway].
        gateway!: string

        // Specific listener section on the Gateway. Optional when the Gateway
        // has a single matching listener.
        listener?: string

        // Hostnames served by every HTTPRoute emitted for this policy.
        // Must intersect with the target Gateway listener's hostnames.
        hostnames!: [...string] & list.MinItems(1)

        // Filters applied to every emitted HTTPRoute before per-rule filters.
        defaultFilters?: [...#HTTPRouteFilter]

        // Defaults for per-rule timeouts when a rule does not override.
        defaultTimeouts?: close({
            request?:        string
            backendRequest?: string
        })
    }
}
```

## `#HTTPRouteTransformer`

```cue
// catalog/gateway_api/v1alpha1/transformers/http_route.cue
package transformers

import (
    transformer "opmodel.dev/core/v1alpha1/transformer@v1"
    routing "opmodel.dev/opm/v1alpha1/operations/routing@v1"
)

#HTTPRouteTransformer: transformer.#PolicyTransformer & {
    metadata: {
        modulePath:  "opmodel.dev/gateway_api/v1alpha1/transformers"
        version:     "v1"
        name:        "http-route-transformer"
        description: "Renders a #HTTPRoutePolicy + components' #HTTPRouteTrait into Gateway API HTTPRoute CRs"
    }

    requiredDirectives: [routing.#HTTPRoutePolicy.metadata.fqn]
    requiredTraits:     [routing.#HTTPRouteTrait.metadata.fqn]

    readsContext: ["routing.gateways"]

    producesKinds: ["gateway.networking.k8s.io/v1.HTTPRoute"]

    // Cardinality: N outputs per directive. One HTTPRoute per covered component.
    // Gateway API natively merges routes attached to the same Gateway listener.
}
```

Provider registration:

```cue
#Provider: provider.#Provider & {
    metadata: { name: "gateway-api", type: "kubernetes", version: "1.2.0" }
    #policyTransformers: {
        (transformers.#HTTPRouteTransformer.metadata.fqn): transformers.#HTTPRouteTransformer
        // ... sibling transformers for TLS/GRPC/TCP/UDP routes ...
    }
}
```

## Module Author Experience — Mixed Paths, Shared Hostname

```cue
#components: {
    "web": #StatelessWorkload & routing.#HTTPRouteTrait & {
        spec: {
            container: { image: "strix-web:latest", ports: [{name: "http", containerPort: 3000}] }
            httpRoute: rules: [{
                matches: [{path: {type: "PathPrefix", value: "/"}}]
                backendPort: 3000
            }]
        }
    }

    "api": #StatelessWorkload & routing.#HTTPRouteTrait & {
        spec: {
            container: { image: "strix-api:latest", ports: [{name: "http", containerPort: 8080}] }
            httpRoute: rules: [{
                matches: [{path: {type: "PathPrefix", value: "/api"}}]
                backendPort: 8080
                filters: [{
                    type: "URLRewrite"
                    urlRewrite: path: { type: "ReplacePrefixMatch", replacePrefixMatch: "/" }
                }]
            }]
        }
    }
}

#policies: {
    "public-routes": policy.#Policy & {
        appliesTo: components: ["web", "api"]
        #directives: {
            (routing.#HTTPRoutePolicy.metadata.fqn): routing.#HTTPRoutePolicy & {
                #spec: httpRoute: {
                    gateway:   "public-web"
                    listener:  "https"
                    hostnames: ["strix.\(#ctx.runtime.route.domain)"]
                    defaultFilters: [{
                        type: "RequestHeaderModifier"
                        requestHeaderModifier: add: [{name: "X-Forwarded-Via", value: "strix-gateway"}]
                    }]
                }
            }
        }
    }
}
```

Platform side:

```cue
#Platform & {
    #ctx: platform: routing: gateways: {
        "public-web": {
            namespace: "gateway-system"
            listeners: {
                "https": { port: 443, protocol: "HTTPS" }
                "http":  { port: 80,  protocol: "HTTP" }
            }
        }
        "internal": {
            namespace: "gateway-system"
            listeners: "https": { port: 443, protocol: "HTTPS" }
        }
    }
}
```

Rendered output — two `HTTPRoute` CRs, one per covered component, both attached to the same Gateway listener with the same hostname. Gateway API merges them on the Gateway side; different paths produce distinct routing behavior.

```yaml
# HTTPRoute for web
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: strix-media-web-http
  namespace: media
  annotations:
    opm.opmodel.dev/owner-policy:      public-routes
    opm.opmodel.dev/owner-directive:   opmodel.dev/opm/v1alpha1/operations/routing/http-route@v1
    opm.opmodel.dev/owner-transformer: opmodel.dev/gateway_api/v1alpha1/transformers/http-route-transformer@v1
    opm.opmodel.dev/owner-component:   web
spec:
  parentRefs:
    - kind: Gateway
      namespace: gateway-system
      name: public-web
      sectionName: https
  hostnames: [strix.dev.example.com]
  rules:
    - matches: [{path: {type: PathPrefix, value: /}}]
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier: {add: [{name: X-Forwarded-Via, value: strix-gateway}]}
      backendRefs:
        - kind: Service
          name: strix-media-web
          port: 3000

---
# HTTPRoute for api — same gateway, same hostname, different path + rewrite
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: strix-media-api-http
  namespace: media
  annotations:
    opm.opmodel.dev/owner-policy:      public-routes
    opm.opmodel.dev/owner-directive:   opmodel.dev/opm/v1alpha1/operations/routing/http-route@v1
    opm.opmodel.dev/owner-transformer: opmodel.dev/gateway_api/v1alpha1/transformers/http-route-transformer@v1
    opm.opmodel.dev/owner-component:   api
spec:
  parentRefs:
    - kind: Gateway
      namespace: gateway-system
      name: public-web
      sectionName: https
  hostnames: [strix.dev.example.com]
  rules:
    - matches: [{path: {type: PathPrefix, value: /api}}]
      filters:
        - type: RequestHeaderModifier
          requestHeaderModifier: {add: [{name: X-Forwarded-Via, value: strix-gateway}]}
        - type: URLRewrite
          urlRewrite: {path: {type: ReplacePrefixMatch, replacePrefixMatch: /}}
      backendRefs:
        - kind: Service
          name: strix-media-api
          port: 8080
```

## Siblings — TLSRoute, GRPCRoute, TCPRoute, UDPRoute

Each protocol follows the same trait + directive + transformer pattern. Summary of specializations:

### `#TLSRouteTrait` / `#TLSRoutePolicy`

- Trait carries only `backendPort` + optional `weight`. No filters (TLS passthrough has no visibility into content).
- Directive carries `gateway`, `listener`, `hostnames` (SNI list), and optionally `mode: "Passthrough" | "Terminate"`. For Terminate mode the Gateway terminates TLS and the route handles cleartext — effectively a TCP route after termination.
- Transformer emits one `TLSRoute` CR per covered component.

### `#GRPCRouteTrait` / `#GRPCRoutePolicy`

- Trait `rules[]` carries `matches` of shape `{method: {service: string, method: string}}` and `headers` (gRPC metadata).
- Filters are HTTP-ish: header modification, mirroring. No URL rewrite.
- Directive shape identical to `#HTTPRoutePolicy` except filter types are `#GRPCRouteFilter`.
- Transformer emits one `GRPCRoute` CR per covered component.

### `#TCPRouteTrait` / `#TCPRoutePolicy`

- Trait carries only `backendPort` + optional `weight`. No matches (routing is entirely at the listener's `port`).
- Directive carries `gateway` + `listener`. Hostnames field is absent — TCP routing is connection-level, not content-level.
- Transformer emits one `TCPRoute` CR per covered component.

### `#UDPRouteTrait` / `#UDPRoutePolicy`

- Same shape as TCP. Exists because Gateway API distinguishes TCP and UDP at the CR type level.

### Why one directive per protocol rather than a unified `#RoutingPolicy`

Filters are protocol-specific. Hostname semantics differ (HTTP vs. SNI vs. absent). A single `#RoutingPolicy` with conditional schema on a `protocol` field becomes a large union type with little type safety. One directive per protocol — sharing the core skeleton — keeps each individually precise.

Modules that mix protocols simply import the package once and use the appropriate pairs. Authoring cost is proportional to protocol count, which is usually one (HTTP).

## Cross-Commodity Observation

Routes do NOT reference TLS commodity output. Gateway listeners terminate TLS using cert Secrets — configured by the platform team at Gateway install time, outside the module's scope. Modules that serve TLS behind an existing Gateway need only to attach their routes; the TLS commodity is orthogonal.

This reinforces the principle that cross-commodity coupling **defaults to decoupling via the platform layer**, not coupling via transformer output. A directive does not read another directive's output. A module author uses `#ctx.runtime.route.domain` and `#ctx.platform.<commodity>.<resource>` as shared vocabulary, not inter-transformer data flow. See [D12](08-decisions.md) (policy pass acyclicity) and [OQ-4](09-open-questions.md) (ordering among policy transformers).

## What This Example Confirms

| Aspect | Backup | TLS | Routing | Consistent? |
| --- | --- | --- | --- | --- |
| Trait + Directive split | ✓ | ✓ | ✓ | yes |
| `#PolicyTransformer` scope | ✓ | ✓ | ✓ | yes |
| Platform-ctx subtree for provider config | `backup.backends` | `tls.issuers` | `routing.gateways` | yes (see [D14](08-decisions.md) for convention) |
| Output cardinality | 1 per policy | N per policy | N per policy | supported by optional `owner-component` annotation |
| Version pairing via shared package | ✓ | ✓ | ✓ | yes |
| Cross-commodity coupling via platform, not output | n/a (standalone) | n/a (standalone) | ✓ (decoupled from TLS) | yes |

Three data points agree. [OQ-5](09-open-questions.md) is closed with this example: the pattern generalizes.

## What This Example Does Not Address

- **`BackendTLSPolicy`** (Gateway API v1.2+) for TLS between Gateway and backend. A separate commodity if operators want to declare mTLS to their upstream services.
- **`ReferenceGrant`**. Cross-namespace `backendRef` requires `ReferenceGrant` resources. Platform-team concern; route transformer does not emit them.
- **Aggregated-route authoring shape.** Today each component emits its own `HTTPRoute`. A future option could allow a policy to emit a single aggregated `HTTPRoute` across its `appliesTo` set — but only if noise from per-component output becomes a real problem. Gateway API merges natively at the listener, so the functional behavior is identical either way.
