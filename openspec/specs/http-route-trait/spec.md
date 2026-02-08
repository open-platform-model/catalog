## Requirements

### Requirement: Shared route base schemas

The schemas module SHALL define shared base types for route traits in `schemas/network.cue`:

- `#RouteHeaderMatch`: A struct with required `name` (string) and required `value` (string) for matching request headers.
- `#RouteRuleBase`: A struct with required `backendPort` (int, valid port range 1-65535) representing the target port on the backing service.
- `#RouteAttachmentSchema`: A struct with optional `gatewayRef` (struct with required `name` string and optional `namespace` string), optional `tls` (struct with optional `mode` defaulting to `"Terminate"` constrained to `"Terminate"` or `"Passthrough"`, and optional `certificateRef` struct with required `name` string and optional `namespace` string), and optional `ingressClassName` (string).

These base types SHALL be reused by `#HttpRouteSchema`, `#GrpcRouteSchema`, and `#TcpRouteSchema`.

#### Scenario: Base types compose into protocol-specific schemas

- **WHEN** `#HttpRouteSchema` defines a rule struct
- **THEN** the rule struct SHALL embed `#RouteRuleBase` and add HTTP-specific match fields

#### Scenario: Attachment fields are available on all route schemas

- **WHEN** `#HttpRouteSchema` is evaluated
- **THEN** the schema SHALL accept optional `gatewayRef`, `tls`, and `ingressClassName` fields via `#RouteAttachmentSchema` embedding

### Requirement: HttpRoute schema definition

The schemas module SHALL define an `#HttpRouteSchema` that embeds `#RouteAttachmentSchema` and specifies HTTP routing rules. The schema SHALL include an optional `hostnames` field (list of strings) for host-based matching. The schema SHALL include a required `rules` field (list, minimum one entry) where each rule embeds `#RouteRuleBase` and adds an optional `matches` list. Each match entry SHALL support optional fields: `path` (struct with `type` constrained to `"Prefix"`, `"Exact"`, or `"RegularExpression"` defaulting to `"Prefix"`, and required `value` string), `headers` (list of `#RouteHeaderMatch`), and `method` (constrained to standard HTTP methods).

#### Scenario: Schema validates a basic HTTP route with path matching

- **WHEN** a component specifies `httpRoute: { rules: [{ matches: [{ path: { value: "/api" } }], backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value with `path.type` defaulting to `"Prefix"`

#### Scenario: Schema validates host-based routing

- **WHEN** a component specifies `httpRoute: { hostnames: ["api.example.com"], rules: [{ backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates header and method matching

- **WHEN** a component specifies `httpRoute: { rules: [{ matches: [{ method: "POST", headers: [{ name: "X-Api-Version", value: "v2" }] }], backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema rejects empty rules

- **WHEN** a component specifies `httpRoute: { rules: [] }`
- **THEN** the schema SHALL reject the value because at least one rule MUST be present

#### Scenario: Schema rejects invalid path type

- **WHEN** a component specifies `httpRoute: { rules: [{ matches: [{ path: { type: "Glob", value: "/*" } }], backendPort: 8080 }] }`
- **THEN** the schema SHALL reject the value because `type` MUST be one of `"Prefix"`, `"Exact"`, or `"RegularExpression"`

#### Scenario: Schema accepts gateway reference

- **WHEN** a component specifies `httpRoute: { gatewayRef: { name: "main-gateway", namespace: "infra" }, rules: [{ backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema accepts TLS configuration

- **WHEN** a component specifies `httpRoute: { tls: { mode: "Terminate", certificateRef: { name: "app-cert" } }, rules: [{ backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value with TLS mode `"Terminate"`

#### Scenario: Schema accepts TLS with default mode

- **WHEN** a component specifies `httpRoute: { tls: { certificateRef: { name: "app-cert" } }, rules: [{ backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value with `tls.mode` defaulting to `"Terminate"`

#### Scenario: Schema accepts ingressClassName

- **WHEN** a component specifies `httpRoute: { ingressClassName: "nginx", rules: [{ backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema accepts all attachment fields together

- **WHEN** a component specifies `httpRoute: { ingressClassName: "nginx", gatewayRef: { name: "gw" }, tls: { mode: "Terminate" }, hostnames: ["app.example.com"], rules: [{ backendPort: 8080 }] }`
- **THEN** the schema SHALL accept the value

### Requirement: HttpRoute trait definition

The traits module SHALL define an `#HttpRouteTrait` in `traits/network/http_route.cue` that wraps `#HttpRouteSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `rules: [{backendPort: 8080}]` as a sensible starting point.

#### Scenario: Trait composes with a component

- **WHEN** a component includes `#Container` resource and `#HttpRoute` trait
- **THEN** the component SHALL validate successfully and expose `spec.httpRoute` in its spec

### Requirement: HttpRoute trait semantically depends on Expose

The HttpRoute trait SHALL semantically depend on the Expose trait — a route forwards traffic to an exposed service. This dependency SHALL be enforced by the transformer (requiring both traits in `requiredTraits`), not by the trait definition itself. Exception: the K8s Ingress transformer requires only HttpRoute because `backendPort` is on the route rules and the service name is derived from the component name.

#### Scenario: Transformer enforces the Expose dependency

- **WHEN** a transformer for HttpRoute evaluates a component
- **THEN** the transformer SHALL require the HttpRoute trait (and optionally the Expose trait depending on the target resource)
