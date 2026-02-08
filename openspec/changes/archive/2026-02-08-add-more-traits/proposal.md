## Why

The current trait catalog covers basic workload lifecycle (replicas, restart, update strategy, health checks) but lacks traits needed for production deployments: security hardening, traffic routing, resilience guarantees, graceful lifecycle management, and workload placement. Without these, module authors must either leave critical concerns unspecified or encode provider-specific details directly into components.

## What Changes

- Add `security/SecurityContext` trait for container/pod security hardening (non-root, capabilities, read-only filesystem)
- Add `network/HttpRoute` trait for HTTP routing with host, path, header, and method matching
- Add `network/GrpcRoute` trait for gRPC routing with service and method matching
- Add `network/TcpRoute` trait for TCP port-forwarding
- Add shared `#RouteAttachmentSchema` with optional `gatewayRef`, `tls`, and `className` fields embedded by all route schemas
- Add `workload/DisruptionBudget` trait for availability guarantees during voluntary disruptions
- Add `workload/GracefulShutdown` trait for termination grace period and pre-stop hooks
- Add `workload/Placement` trait for topology spread, node requirements, and failure domain distribution
- Add corresponding schemas in the `schemas` module for each new trait, with shared base schemas for route traits

## Capabilities

### New Capabilities

- `security-context-trait`: Container and pod-level security constraints (runAsNonRoot, capabilities, readOnlyRootFilesystem, privilege escalation)
- `http-route-trait`: HTTP routing rules with host, path, header, and method matching, plus optional platform attachment (gatewayRef, TLS, className)
- `grpc-route-trait`: gRPC routing rules with service and method matching, plus optional platform attachment
- `tcp-route-trait`: TCP port-forwarding rules, plus optional platform attachment
- `disruption-budget-trait`: Availability constraints during voluntary disruptions (minAvailable, maxUnavailable)
- `graceful-shutdown-trait`: Termination grace period and pre-stop lifecycle hooks
- `placement-trait`: Workload placement intent — topology spread across failure domains, node requirements

### Modified Capabilities

_None_

## Impact

- **Modules affected**: schemas (new schema definitions), traits (new trait definitions)
- **SemVer**: MINOR — additive, no breaking changes to existing definitions
- **Portability**: All traits are provider-agnostic. Route traits model protocol-level routing with optional platform attachment fields (`gatewayRef`, `tls`, `className`) — when omitted, the platform provides defaults. Placement uses abstract concepts (`spreadAcross: "zones"`) with a `platformOverrides` escape hatch.
- **Downstream**: The `add-transformers` change will need to wire these traits into K8s transformer outputs. Route traits map to Gateway API resources (HTTPRoute, GRPCRoute, TCPRoute) and K8s Ingress. The Ingress transformer consumes HttpRoute directly. Existing workload transformers should list applicable new traits as optional traits.
- **Dependencies**: No new module dependencies. All new traits follow existing patterns (appliesTo Container resource, schema in schemas module, trait definition in traits module).
