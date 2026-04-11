# Design Package: `#Platform`, `#Environment` & Provider Composition

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Platform` as a core construct that composes a base provider with capability providers into a unified transformer registry. `#Platform` carries platform-level `#ctx` defaults (cluster domain, platform extensions) following the enhancement 003 `#ctx` pattern.

Introduce `#Environment` as the user-facing deployment target that references a `#Platform` and contributes environment-level `#ctx` overrides (namespace, route domain). `#ModuleRelease` targets an environment via `#env`, not a platform directly.

Context resolution follows a layered hierarchy: CUE defaults → `#Platform.#ctx` → `#Environment.#ctx` → `#ModuleRelease` identity. This supersedes enhancement 003's inline `#environment` field on `#ModuleRelease`.

The existing matcher works unchanged — it receives the composed transformer map. CUE struct unification handles provider composition naturally.

Claim/offer extensions to `#Transformer`, `#Provider`, and `#Platform` are owned by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/).

## Documents

1. [01-problem.md](01-problem.md) — Monolithic provider; no composition point for capability modules
2. [02-design.md](02-design.md) — `#Platform` construct, context hierarchy, provider composition via CUE unification
3. [03-module-integration.md](03-module-integration.md) — Platform operator, environment operator, release author, and capability module author experience
4. [04-decisions.md](04-decisions.md) — All design decisions with rationale
5. [05-environment.md](05-environment.md) — `#Environment` construct: schema, file layout, context hierarchy, `#ContextBuilder` changes, relationship to enhancement 003

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/003-module-context/` | Enhancement 003 — `#ctx`, `#RuntimeContext`, `#ContextBuilder`. This enhancement supersedes 003's inline `#environment` with the `#Environment` construct |
| `catalog/enhancements/006-claim-primitive/` | `#Claim` primitive — owns `requiredClaims`/`optionalClaims` on `#Transformer`, `#declaredClaims` on `#Provider`, matcher claim matching |
| `catalog/enhancements/007-offer-primitive/` | `#Offer` primitive — owns `#offers`/`#declaredOffers` on `#Provider`, `#composedOffers`/`#satisfiedClaims` on `#Platform` |
| `catalog/core/v1alpha1/provider/provider.cue` | Existing `#Provider` definition — gains `metadata.type` from this enhancement |
| `catalog/opm/v1alpha1/providers/kubernetes/provider.cue` | Base Kubernetes provider (16 transformers) |
| `catalog/k8up/v1alpha1/providers/kubernetes/provider.cue` | Existing capability provider (K8up, 4 transformers) |
