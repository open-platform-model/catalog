## Tasks

### Schemas

- [ ] Add `#SecurityContextSchema` to new `schemas/security.cue`
- [ ] Add `#RouteHeaderMatch` shared base to `schemas/network.cue`
- [ ] Add `#RouteRuleBase` shared base to `schemas/network.cue`
- [ ] Add `#HttpRouteMatchSchema` and `#HttpRouteRuleSchema` and `#HttpRouteSchema` to `schemas/network.cue`
- [ ] Add `#GrpcRouteMatchSchema` and `#GrpcRouteRuleSchema` and `#GrpcRouteSchema` to `schemas/network.cue`
- [ ] Add `#TcpRouteRuleSchema` and `#TcpRouteSchema` to `schemas/network.cue`
- [ ] Add `#DisruptionBudgetSchema` to `schemas/workload.cue`
- [ ] Add `#GracefulShutdownSchema` to `schemas/workload.cue`
- [ ] Add `#PlacementSchema` to `schemas/workload.cue`
- [ ] Run `task vet MODULE=schemas`

### Traits

- [ ] Add `#SecurityContextTrait`, `#SecurityContext`, `#SecurityContextDefaults` to `traits/security/security_context.cue`
- [ ] Add `#HttpRouteTrait`, `#HttpRoute`, `#HttpRouteDefaults` to `traits/network/http_route.cue`
- [ ] Add `#GrpcRouteTrait`, `#GrpcRoute`, `#GrpcRouteDefaults` to `traits/network/grpc_route.cue`
- [ ] Add `#TcpRouteTrait`, `#TcpRoute`, `#TcpRouteDefaults` to `traits/network/tcp_route.cue`
- [ ] Add `#DisruptionBudgetTrait`, `#DisruptionBudget`, `#DisruptionBudgetDefaults` to `traits/workload/disruption_budget.cue`
- [ ] Add `#GracefulShutdownTrait`, `#GracefulShutdown`, `#GracefulShutdownDefaults` to `traits/workload/graceful_shutdown.cue`
- [ ] Add `#PlacementTrait`, `#Placement`, `#PlacementDefaults` to `traits/workload/placement.cue`
- [ ] Run `task vet MODULE=traits`

### Validation

- [ ] Run `task fmt` across all affected modules
- [ ] Run `task vet` across all modules to confirm no breakage
