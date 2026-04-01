# Design Package: `#Platform` Construct & Provider Composition

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Platform` as a core construct that composes a base provider with capability providers into a unified transformer registry. This extends RFC-0001's platform concept (cluster targeting + context) with provider composition, enabling capability modules (K8up, cert-manager, CloudNativePG) to contribute their transformers to the platform.

The existing matcher works unchanged — it receives the composed transformer map. CUE struct unification handles provider composition naturally.

Additionally, the `#Transformer` gains `requiredClaims`/`optionalClaims` matching (from enhancement 006), and `#Provider` gains `#declaredClaims` auto-computation, enabling the CLI to warn about unfulfilled claims.

## Documents

1. [01-problem.md](01-problem.md) — Monolithic provider; no composition point for capability modules; matcher lacks claim matching
2. [02-design.md](02-design.md) — `#Platform` construct, provider composition via CUE unification, `#declaredClaims`
3. [03-matcher-claims.md](03-matcher-claims.md) — `requiredClaims` on Transformer, `missingClaims` in MatchResult, `unhandledClaims`
4. [04-module-integration.md](04-module-integration.md) — Platform operator and capability module author experience
5. [05-decisions.md](05-decisions.md) — All design decisions with rationale

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/docs/rfc/0001-environment-definition.md` | RFC-0001 Platform concept — extended here with provider composition |
| `catalog/enhancements/006-claim-primitive/` | `#Claim` primitive and `requiredClaims` on transformers |
| `catalog/enhancements/007-offer-primitive/` | `#Offer` primitive — module-level capability declarations with linked Transformers; Platform gains `#composedOffers` |
| `catalog/core/v1alpha1/provider/provider.cue` | Existing `#Provider` definition — gains `#declaredClaims` |
| `catalog/core/v1alpha1/transformer/transformer.cue` | Existing `#Transformer` — gains `requiredClaims`/`optionalClaims` |
| `catalog/core/v1alpha1/matcher/matcher.cue` | Existing matcher — gains claim matching |
| `catalog/opm/v1alpha1/providers/kubernetes/provider.cue` | Base Kubernetes provider (16 transformers) |
| `catalog/k8up/v1alpha1/providers/kubernetes/provider.cue` | Existing capability provider (K8up, 4 transformers) |
