## ADDED Requirements

### Requirement: TcpRoute schema definition

The schemas module SHALL define a `#TcpRouteSchema` that embeds `#RouteAttachmentSchema` and specifies TCP port-forwarding rules. The schema SHALL include a required `rules` field (list, minimum one entry) where each rule embeds `#RouteRuleBase` (providing `backendPort`). TCP routes SHALL NOT support hostname matching, header matching, or other L7 constructs — they operate at L4 only.

#### Scenario: Schema validates a basic TCP route

- **WHEN** a component specifies `tcpRoute: { rules: [{ backendPort: 5432 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates multiple backend ports

- **WHEN** a component specifies `tcpRoute: { rules: [{ backendPort: 5432 }, { backendPort: 6379 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema rejects empty rules

- **WHEN** a component specifies `tcpRoute: { rules: [] }`
- **THEN** the schema SHALL reject the value because at least one rule MUST be present

#### Scenario: Schema rejects invalid port

- **WHEN** a component specifies `tcpRoute: { rules: [{ backendPort: 0 }] }`
- **THEN** the schema SHALL reject the value because port MUST be in range 1-65535

#### Scenario: Schema accepts gateway reference

- **WHEN** a component specifies `tcpRoute: { gatewayRef: { name: "tcp-gateway" }, rules: [{ backendPort: 5432 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema accepts TLS passthrough

- **WHEN** a component specifies `tcpRoute: { tls: { mode: "Passthrough" }, rules: [{ backendPort: 5432 }] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema accepts ingressClassName

- **WHEN** a component specifies `tcpRoute: { ingressClassName: "cilium", rules: [{ backendPort: 5432 }] }`
- **THEN** the schema SHALL accept the value

### Requirement: TcpRoute trait definition

The traits module SHALL define a `#TcpRouteTrait` in `traits/network/tcp_route.cue` that wraps `#TcpRouteSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `rules: [{backendPort: 8080}]` as a sensible starting point.

#### Scenario: Trait composes with a component

- **WHEN** a component includes `#Container` resource and `#TcpRoute` trait
- **THEN** the component SHALL validate successfully and expose `spec.tcpRoute` in its spec

### Requirement: TcpRoute trait semantically depends on Expose

The TcpRoute trait SHALL semantically depend on the Expose trait. This dependency SHALL be enforced by the transformer, not by the trait definition itself.

#### Scenario: Transformer enforces the Expose dependency

- **WHEN** a transformer for TcpRoute evaluates a component
- **THEN** the transformer SHALL require both the TcpRoute trait and the Expose trait
