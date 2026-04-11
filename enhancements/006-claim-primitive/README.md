# Design Package: `#Claim` Primitive & Policy Broadening

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Claim` as a new component-level primitive alongside `#Resource` and `#Trait`. A Claim declares what a component needs from the platform — typed data contracts (e.g., Postgres connection) and operational contracts (e.g., backup scheduling). Claims compose into Blueprints, maintaining OPM's core composability model.

Simultaneously, broaden `#Policy` to serve two audiences by splitting its primitive types: `#Rule` (platform -> module governance) and `#Orchestration` (module -> platform cross-component coordination). This gives module authors a place to define restore procedures, shared networking, and other concerns that span multiple components.

This enhancement supersedes [005-requirement-primitive](../005-requirement-primitive/) and subsumes the interface concepts from [RFC-0004](../../../cli/docs/rfc/0004-interface-architecture.md).

The companion primitive `#Offer` (what a component provides to others) is deferred to enhancement 007.

## Documents

1. [01-problem.md](01-problem.md) — Isolated components; no dependency declaration; operational needs unmodeled; Blueprint composability gap
2. [02-design.md](02-design.md) — `#Claim` primitive (component-level, Blueprint-composable); broadened `#Policy` with `#Rule` and `#Orchestration`
3. [03-well-known-claims.md](03-well-known-claims.md) — Data interface claims: Postgres, Redis, MySQL, S3, HTTP, gRPC
4. [04-operational-claims.md](04-operational-claims.md) — Operational claims: backup; Policy orchestrations: restore, shared network
5. [05-fulfillment.md](05-fulfillment.md) — Platform fulfillment strategies; value injection; CUE late-binding investigation
6. [06-module-integration.md](06-module-integration.md) — Author experience; wiring patterns; Blueprint composition; concrete examples
7. [07-rendering-pipeline.md](07-rendering-pipeline.md) — Claim transformers/resolvers; independent from trait pipeline
8. [08-decisions.md](08-decisions.md) — All design decisions with rationale and alternatives

## Counterpart: `#Offer`

The `#Offer` primitive — declaring what a module provides to the platform — is designed in [enhancement 007](../007-offer-primitive/). This includes:

- `#Offer` declarations on modules (e.g., "K8up offers backup capability")
- Offer/Claim pairing with version matching
- Offer-linked Transformers for capability providers
- Platform capability reporting and pre-render validation

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `cli/docs/rfc/0004-interface-architecture.md` | Original Interface RFC — provides/requires, well-known types, fulfillment |
| `catalog/enhancements/005-requirement-primitive/` | Predecessor — `#Requirement` primitive design (superseded) |
| `catalog/docs/design-principles.md` | OPM principles, especially II (Separation of Concerns) and III (Composability) |
| `catalog/docs/core/primitives.md` | Current primitive taxonomy (to be extended with `#Claim`) |
| `catalog/docs/core/constructs.md` | Current construct taxonomy (`#Policy` broadened, `#Blueprint` extended) |
| `catalog/core/v1alpha1/primitives/` | Existing primitive definitions |
| `catalog/core/v1alpha1/policy/policy.cue` | `#Policy` construct (to gain `#Rule` and `#Orchestration`) |
| `catalog/core/v1alpha1/component/component.cue` | `#Component` (to gain `#claims` field) |
| `catalog/enhancements/007-offer-primitive/` | `#Offer` primitive — the supply-side counterpart to `#Claim` |
| `catalog/enhancements/008-platform-construct/` | `#Platform` construct — composes providers and their offers |
