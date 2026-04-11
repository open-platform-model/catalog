# Design Package: Module Context, Platform Composition, and Environment Targeting

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

## Summary

Introduces `#ctx`, a well-known definition field on `#Module` that makes runtime and environment information available to components at definition time. Module authors can reference the release name, namespace, cluster domain, route domain, computed resource names, and DNS variations without hardcoding values or requiring manual user input for derived configuration.

Introduces `#Platform` as a core construct that composes a base provider with capability providers into a unified transformer registry. `#Platform` carries platform-level `#ctx` defaults (cluster domain, platform extensions) typed as `#PlatformContext`.

Introduces `#Environment` as the user-facing deployment target that references a `#Platform` and contributes environment-level `#ctx` overrides (namespace, route domain) typed as `#EnvironmentContext`. `#ModuleRelease` targets an environment via `#env`, not a platform directly.

Context resolution follows a layered hierarchy: `#Platform.#ctx` (`#PlatformContext`) → `#Environment.#ctx` (`#EnvironmentContext`) → `#ModuleRelease` identity → `#ModuleContext`.

The existing matcher works unchanged — it receives the composed transformer map. CUE struct unification handles provider composition naturally.

Claim/offer extensions to `#Transformer`, `#Provider`, and `#Platform` are owned by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/).

> **Note:** This enhancement subsumes the former enhancement 003-module-context. All context schemas, pipeline changes, and design decisions from 003 are merged here. Enhancement 003 is archived with a pointer to this document.

## Documents

1. [01-problem.md](01-problem.md) — Module blindness to deployment context; monolithic provider with no composition point
2. [02-design.md](02-design.md) — Architectural overview: `#ctx` two-layer design, context hierarchy, provider composition, before/after examples
3. [03-schema.md](03-schema.md) — All schema definitions: `#ModuleContext`, `#PlatformContext`, `#EnvironmentContext`, `#RuntimeContext`, `#ComponentNames`, `#Platform`, `#Environment`, `#ContextBuilder`, `#ModuleRelease` changes
4. [04-platform.md](04-platform.md) — `#Platform` construct: file layout, provider composition, ordering, capability module author experience
5. [05-environment.md](05-environment.md) — `#Environment` construct: file layout, examples, sharing, context hierarchy resolution, CLI commands
6. [06-module-integration.md](06-module-integration.md) — Pipeline integration: end-to-end flow, `#ModuleRelease` changes, Go pipeline changes, content hash injection, release author experience, CLI workflow
7. [07-decisions.md](07-decisions.md) — All design decisions with rationale (D1-D30)
8. [08-notes.md](08-notes.md) — Deferred discussions, open questions, and follow-up triggers

## Open Questions and Deferred Items

All items flagged during design as requiring further discussion are tracked in [08-notes.md](08-notes.md). The notes file distinguishes between:

- **Deferred decisions** — topics explicitly considered and set aside for a follow-up design (e.g., `#TransformerContext` migration, bundle-level context)
- **Implementation notes** — constraints the initial implementer must keep in mind to avoid closing off future options (e.g., override support, environment profile sharing)
- **Follow-up design triggers** — conditions under which a deferred item should be revisited (e.g., Strategy A for content hashes, `platform` namespacing)

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/003-module-context/` | Archived — merged into this enhancement |
| `catalog/enhancements/002-resource-name-override/` | Archived — resource name override subsumed by `metadata.resourceName` (D13) |
| `catalog/enhancements/006-claim-primitive/` | `#Claim` primitive — owns `requiredClaims`/`optionalClaims` on `#Transformer`, `#declaredClaims` on `#Provider`, matcher claim matching |
| `catalog/enhancements/007-offer-primitive/` | `#Offer` primitive — owns `#offers`/`#declaredOffers` on `#Provider`, `#composedOffers`/`#satisfiedClaims` on `#Platform` |
| `catalog/core/v1alpha1/provider/provider.cue` | Existing `#Provider` definition — gains `metadata.type` from this enhancement |
| `catalog/opm/v1alpha1/providers/kubernetes/provider.cue` | Base Kubernetes provider (16 transformers) |
| `catalog/k8up/v1alpha1/providers/kubernetes/provider.cue` | Existing capability provider (K8up, 4 transformers) |
