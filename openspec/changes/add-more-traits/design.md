## Context

The OPM catalog currently has 11 traits across two categories (workload and network) plus one security trait (Encryption). All follow the same pattern: a schema in the `schemas` module, a trait definition in the `traits` module that wraps the schema, a `#defaults` value, and a companion component mixin (`#Trait` → `#Component`).

This change adds 7 new traits across 3 categories (security, network, workload) following the same established patterns. Route traits introduce shared base schemas for DRY composition but no new architectural concepts.

Existing trait pattern for reference:

```text
schemas/         → #FooSchema (closed struct with constraints)
traits/<cat>/    → #FooTrait (wraps schema, declares appliesTo, provides #defaults)
                 → #Foo (component mixin: close(core.#Component & { #traits: ... }))
                 → #FooDefaults (concrete default values)
```

## Goals / Non-Goals

**Goals:**

- Add SecurityContext, HttpRoute, GrpcRoute, TcpRoute, DisruptionBudget, GracefulShutdown, and Placement traits
- Share base schemas across route traits to avoid duplication
- Follow existing trait patterns — no new abstractions
- Keep all traits provider-agnostic, deferring K8s-specific mapping to the `add-transformers` change
- Ensure all new schemas use CUE constraints for compile-time validation

**Non-Goals:**

- K8s transformer implementations (covered by `add-transformers` change)
- Gateway/infrastructure-level routing config (platform concern, not module-author concern)
- TLS termination on routes (platform concern, handled at gateway level)
- Blueprint updates to compose new traits (separate follow-up)
- Workload schema updates (e.g., adding traits to `#StatelessWorkloadSchema`) — those schemas are `close()`d and would need explicit updates in a follow-up

## Decisions

### 1. Schema file placement by category

**Decision**: Add schemas to the file matching their category:

- `schemas/workload.cue` — DisruptionBudget, GracefulShutdown, Placement
- `schemas/network.cue` — RouteHeaderMatch, RouteRuleBase, HttpRoute, GrpcRoute, TcpRoute
- New `schemas/security.cue` — SecurityContext

**Rationale**: Follows existing convention where `#ExposeSchema` lives in `network.cue` and workload schemas live in `workload.cue`. A new `security.cue` is warranted because security constraints are neither config/secrets nor workload lifecycle.

### 2. Shared base schemas for route traits

**Decision**: Define `#RouteHeaderMatch` and `#RouteRuleBase` in `schemas/network.cue` as shared base types:

```cue
#RouteHeaderMatch: {
    name!:  string
    value!: string
}

#RouteRuleBase: {
    backendPort!: uint & >=1 & <=65535
}
```

Protocol-specific schemas embed the base and add their own match fields:

```cue
#HttpRouteRuleSchema: #RouteRuleBase & {
    matches?: [...#HttpRouteMatchSchema]
}
#GrpcRouteRuleSchema: #RouteRuleBase & {
    matches?: [...#GrpcRouteMatchSchema]
}
#TcpRouteRuleSchema: #RouteRuleBase  // No additional match fields
```

**Alternative considered**: Fully independent schemas per protocol. Rejected because it duplicates `backendPort` validation and `#RouteHeaderMatch` across three schemas.

### 3. Separate traits per protocol (HTTP, gRPC, TCP)

**Decision**: One trait per protocol rather than a single unified `Route` trait.

**Rationale**: Aligns with OPM composability (Principle III) — attach only what you need. Each schema validates exactly its protocol's fields without conditionals, maintaining type safety (Principle I). Maps 1:1 to K8s Gateway API resources.

### 4. No gateway reference in route traits

**Decision**: Route traits do not include `gatewayRef`, `parentRef`, or any reference to gateway infrastructure.

**Rationale**: Gateway attachment is a platform concern, not a module-author concern. The Module Author declares "my workload needs HTTP routing with these rules." The Platform Operator decides which gateway handles it. This follows Principle II (Separation of Concerns) and Principle V (Portability by Design). Gateway binding will be resolved through the Scope/deployment context in a future design.

### 5. No TLS on route traits

**Decision**: TLS termination is not modeled on route traits. No `tls` field.

**Rationale**: TLS termination happens at the gateway/platform level. The Platform Operator configures TLS on the Gateway resource. Module Authors should not need to manage certificates or TLS configuration. This keeps route traits focused on application-level routing intent.

### 6. Route traits semantically depend on Expose

**Decision**: Route traits require the Expose trait to function (a route needs a Service to forward to). This dependency is enforced at the transformer level (`requiredTraits` includes both Route and Expose), not at the trait definition level.

**Rationale**: Follows OPM's composability principle — traits compose independently at the definition level. Cross-trait dependencies are a transformer concern.

### 7. DisruptionBudget mutual exclusion enforcement

**Decision**: Use CUE disjunction to enforce that exactly one of `minAvailable` or `maxUnavailable` is set:

```cue
#DisruptionBudgetSchema: {minAvailable!: int | string} | {maxUnavailable!: int | string}
```

**Alternative considered**: Two optional fields with runtime validation. Rejected because CUE can enforce this at definition time (Principle I).

### 8. Placement `platformOverrides` as open struct

**Decision**: Use `{...}` (open struct) for `platformOverrides` to allow arbitrary provider-specific fields.

**Alternative considered**: Typed per-provider structs. Rejected because it would couple the schemas module to provider-specific knowledge, violating Principle V.

### 9. All traits appliesTo Container resource

**Decision**: All seven traits declare `appliesTo: [workload_resources.#ContainerResource]`, consistent with every existing trait.

### 10. Route rules require minimum one entry

**Decision**: Use CUE list constraint (`[#RuleSchema, ...#RuleSchema]`) to enforce at least one rule in all route schemas.

**Rationale**: A route with no rules is never valid. Enforce structurally at definition time.

## Risks / Trade-offs

**[Placement abstraction may be too narrow]** → The `spreadAcross` enum (`zones`, `regions`, `hosts`) may not capture all topology domains. Mitigation: `platformOverrides` provides an escape hatch. Enum can be extended in future MINOR versions.

**[DisruptionBudget percentage strings are weakly typed]** → Accepting `string` for percentage values means invalid strings could pass. Mitigation: Use regex constraint `=~"^[0-9]+%$"` on string values.

**[Closed workload schemas need separate updates]** → `#StatelessWorkloadSchema` etc. are `close()`d. New traits won't be usable from blueprints until those schemas add the optional fields. This is intentional (explicit > implicit).

**[Gateway binding is deferred]** → Route traits don't specify which gateway handles them. This is a known gap that requires a separate design for Scope-level gateway configuration. Route traits are still useful — they declare intent — but the full routing pipeline isn't complete until gateway binding is designed.

## Migration Plan

No migration needed. All changes are additive (MINOR version bump). Existing definitions continue to validate unchanged.

Deployment order:

1. Add shared base schemas and protocol-specific schemas to `schemas` module
2. Add trait definitions to `traits` module
3. Run `task vet` across all modules to confirm no breakage
4. Workload schema updates and blueprint integration follow separately
