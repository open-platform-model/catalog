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
- Blueprint updates to compose new traits (separate follow-up)
- Workload schema updates (e.g., adding traits to `#StatelessWorkloadSchema`) — those schemas are `close()`d and would need explicit updates in a follow-up

## Decisions

### 1. Schema file placement by category

**Decision**: Add schemas to the file matching their category:

- `schemas/workload.cue` — DisruptionBudget, GracefulShutdown, Placement
- `schemas/network.cue` — RouteHeaderMatch, RouteRuleBase, RouteAttachmentSchema, HttpRoute, GrpcRoute, TcpRoute
- New `schemas/security.cue` — SecurityContext

**Rationale**: Follows existing convention where `#ExposeSchema` lives in `network.cue` and workload schemas live in `workload.cue`. A new `security.cue` is warranted because security constraints are neither config/secrets nor workload lifecycle.

### 2. Shared base schemas for route traits

**Decision**: Define `#RouteHeaderMatch`, `#RouteRuleBase`, and `#RouteAttachmentSchema` in `schemas/network.cue` as shared base types:

```cue
#RouteHeaderMatch: {
    name!:  string
    value!: string
}

#RouteRuleBase: {
    backendPort!: uint & >=1 & <=65535
}

#RouteAttachmentSchema: {
    gatewayRef?: {
        name!:      string
        namespace?: string
    }
    tls?: {
        mode?:           *"Terminate" | "Passthrough"
        certificateRef?: {
            name!:      string
            namespace?: string
        }
    }
    ingressClassName?: string
}
```

Protocol-specific schemas embed `#RouteRuleBase` for rules and `#RouteAttachmentSchema` at the top level:

```cue
#HttpRouteRuleSchema: #RouteRuleBase & {
    matches?: [...#HttpRouteMatchSchema]
}
#GrpcRouteRuleSchema: #RouteRuleBase & {
    matches?: [...#GrpcRouteMatchSchema]
}
#TcpRouteRuleSchema: #RouteRuleBase  // No additional match fields

#HttpRouteSchema: #RouteAttachmentSchema & {
    hostnames?: [...string]
    rules: [#HttpRouteRuleSchema, ...#HttpRouteRuleSchema]
}
// GrpcRouteSchema, TcpRouteSchema follow the same embedding pattern
```

**Alternative considered**: Fully independent schemas per protocol. Rejected because it duplicates `backendPort` validation, `#RouteHeaderMatch`, and attachment fields across three schemas.

### 3. Separate traits per protocol (HTTP, gRPC, TCP)

**Decision**: One trait per protocol rather than a single unified `Route` trait.

**Rationale**: Aligns with OPM composability (Principle III) — attach only what you need. Each schema validates exactly its protocol's fields without conditionals, maintaining type safety (Principle I). Maps 1:1 to K8s Gateway API resources.

### 4. Optional platform attachment on route traits

**Decision**: Route traits include optional `gatewayRef`, `tls`, and `ingressClassName` fields via the shared `#RouteAttachmentSchema`. All fields are optional — module authors may express routing attachment intent, but platform operators can override or default these through Scope/provider configuration.

**Rationale**: Module authors often know which gateway class or TLS mode their workload needs. Making these fields optional preserves Separation of Concerns (Principle II) — the platform operator is not forced to infer intent. When unset, the platform provides defaults. This also enables the K8s Ingress transformer to derive `ingressClassName` and `tls` directly from the route trait without needing a separate Ingress-specific trait.

**Previous position**: Earlier iterations excluded gateway references and TLS from route traits entirely, treating them as pure platform concerns. Revised because: (1) the K8s Ingress transformer needs `ingressClassName` and `tls` data and there is no natural place for it other than the route trait, (2) Gateway API's HTTPRoute itself carries `parentRefs` and the OPM model should be able to express the same intent, (3) keeping them optional preserves the separation — omitting them is equivalent to the old behavior.

### 5. Route traits semantically depend on Expose

**Decision**: Route traits require the Expose trait to function (a route needs a Service to forward to). This dependency is enforced at the transformer level (`requiredTraits` includes both Route and Expose), not at the trait definition level.

**Rationale**: Follows OPM's composability principle — traits compose independently at the definition level. Cross-trait dependencies are a transformer concern. Exception: the K8s Ingress transformer requires only HTTPRoute (not Expose) because `backendPort` is already on the route rules and the service name is derived from the component name.

### 6. DisruptionBudget mutual exclusion enforcement

**Decision**: Use CUE disjunction to enforce that exactly one of `minAvailable` or `maxUnavailable` is set:

```cue
#DisruptionBudgetSchema: {minAvailable!: int | string} | {maxUnavailable!: int | string}
```

**Alternative considered**: Two optional fields with runtime validation. Rejected because CUE can enforce this at definition time (Principle I).

### 7. Placement `platformOverrides` as open struct

**Decision**: Use `{...}` (open struct) for `platformOverrides` to allow arbitrary provider-specific fields.

**Alternative considered**: Typed per-provider structs. Rejected because it would couple the schemas module to provider-specific knowledge, violating Principle V.

### 8. All traits appliesTo Container resource

**Decision**: All seven traits declare `appliesTo: [workload_resources.#ContainerResource]`, consistent with every existing trait.

### 9. Route rules require minimum one entry

**Decision**: Use CUE list constraint (`[#RuleSchema, ...#RuleSchema]`) to enforce at least one rule in all route schemas.

**Rationale**: A route with no rules is never valid. Enforce structurally at definition time.

## Example: HttpRoute (illustrative)

The HttpRoute trait is the most complete route trait. GrpcRoute and TcpRoute follow the same structural pattern (embed `#RouteAttachmentSchema`, wrap in trait, provide component mixin).

### Schema (`schemas/network.cue`)

```cue
#HttpRouteMatchSchema: {
    path?: {
        type:   *"Prefix" | "Exact" | "RegularExpression"
        value!: string
    }
    headers?: [...#RouteHeaderMatch]
    method?:  "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "HEAD" | "OPTIONS"
}

#HttpRouteRuleSchema: #RouteRuleBase & {
    matches?: [...#HttpRouteMatchSchema]
}

#HttpRouteSchema: #RouteAttachmentSchema & {
    hostnames?: [...string]
    rules: [#HttpRouteRuleSchema, ...#HttpRouteRuleSchema]
}
```

### Trait (`traits/network/http_route.cue`)

```cue
package network

import (
    core "opmodel.dev/core@v0"
    schemas "opmodel.dev/schemas@v0"
    workload_resources "opmodel.dev/resources/workload@v0"
)

#HttpRouteTrait: close(core.#Trait & {
    metadata: {
        apiVersion:  "opmodel.dev/traits/network@v0"
        name:        "httpRoute"
        description: "HTTP routing rules for a workload"
    }

    appliesTo: [workload_resources.#ContainerResource]

    #defaults: #HttpRouteDefaults

    #spec: httpRoute: schemas.#HttpRouteSchema
})

#HttpRoute: close(core.#Component & {
    #traits: {(#HttpRouteTrait.metadata.fqn): #HttpRouteTrait}
})

#HttpRouteDefaults: close(schemas.#HttpRouteSchema & {
    rules: [{backendPort: 8080}]
})
```

### Usage in a component

```cue
myApp: core.#Component & #Container & #Expose & #HttpRoute & {
    spec: {
        container: image: "myapp:latest"
        expose: ports: http: { targetPort: 8080 }
        httpRoute: {
            hostnames: ["app.example.com"]
            ingressClassName: "nginx"
            tls: mode: "Terminate"
            gatewayRef: name: "main-gateway"
            rules: [{
                matches: [{path: {value: "/api"}}]
                backendPort: 8080
            }]
        }
    }
}
```

## Risks / Trade-offs

**[Placement abstraction may be too narrow]** → The `spreadAcross` enum (`zones`, `regions`, `hosts`) may not capture all topology domains. Mitigation: `platformOverrides` provides an escape hatch. Enum can be extended in future MINOR versions.

**[DisruptionBudget percentage strings are weakly typed]** → Accepting `string` for percentage values means invalid strings could pass. Mitigation: Use regex constraint `=~"^[0-9]+%$"` on string values.

**[Closed workload schemas need separate updates]** → `#StatelessWorkloadSchema` etc. are `close()`d. New traits won't be usable from blueprints until those schemas add the optional fields. This is intentional (explicit > implicit).

**[Platform attachment fields may be ignored]** → Module authors may set `gatewayRef` or `ingressClassName` but the platform operator's configuration takes precedence. This is by design — the trait expresses intent, the platform resolves it. Documentation should make the override semantics clear.

## Migration Plan

No migration needed. All changes are additive (MINOR version bump). Existing definitions continue to validate unchanged.

Deployment order:

1. Add shared base schemas and protocol-specific schemas to `schemas` module
2. Add trait definitions to `traits` module
3. Run `task vet` across all modules to confirm no breakage
4. Workload schema updates and blueprint integration follow separately
