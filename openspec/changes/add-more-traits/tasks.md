## Tasks

### Schemas

- [x] Add `#SecurityContextSchema` to new `schemas/security.cue`
- [x] Add `#RouteHeaderMatch` shared base to `schemas/network.cue`
- [x] Add `#RouteRuleBase` shared base to `schemas/network.cue`
- [x] Add `#RouteAttachmentSchema` shared base to `schemas/network.cue` (gatewayRef, tls, className)
- [x] Add `#HttpRouteMatchSchema` and `#HttpRouteRuleSchema` and `#HttpRouteSchema` to `schemas/network.cue` (embedding `#RouteAttachmentSchema`)
- [x] Add `#GrpcRouteMatchSchema` and `#GrpcRouteRuleSchema` and `#GrpcRouteSchema` to `schemas/network.cue` (embedding `#RouteAttachmentSchema`)
- [x] Add `#TcpRouteRuleSchema` and `#TcpRouteSchema` to `schemas/network.cue` (embedding `#RouteAttachmentSchema`)
- [x] Add `#DisruptionBudgetSchema` to `schemas/workload.cue`
- [x] Add `#GracefulShutdownSchema` to `schemas/workload.cue`
- [x] Add `#PlacementSchema` to `schemas/workload.cue`
- [x] Run `task vet MODULE=schemas`

### Traits

- [x] Add `#SecurityContextTrait`, `#SecurityContext`, `#SecurityContextDefaults` to `traits/security/security_context.cue`
- [x] Add `#HttpRouteTrait`, `#HttpRoute`, `#HttpRouteDefaults` to `traits/network/http_route.cue`
- [x] Add `#GrpcRouteTrait`, `#GrpcRoute`, `#GrpcRouteDefaults` to `traits/network/grpc_route.cue`
- [x] Add `#TcpRouteTrait`, `#TcpRoute`, `#TcpRouteDefaults` to `traits/network/tcp_route.cue`
- [x] Add `#DisruptionBudgetTrait`, `#DisruptionBudget`, `#DisruptionBudgetDefaults` to `traits/workload/disruption_budget.cue`
- [x] Add `#GracefulShutdownTrait`, `#GracefulShutdown`, `#GracefulShutdownDefaults` to `traits/workload/graceful_shutdown.cue`
- [x] Add `#PlacementTrait`, `#Placement`, `#PlacementDefaults` to `traits/workload/placement.cue`
- [x] Run `task vet MODULE=traits`

### Validation

- [x] Run `task fmt` across all affected modules
- [x] Run `task vet` across all modules to confirm no breakage
