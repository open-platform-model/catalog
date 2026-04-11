# Design Decisions

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for all design choices made during the resource name override feature design.

---

## Decisions

| Decision | Chosen | Rationale | Alternative Considered |
| --- | --- | --- | --- |
| Override scope | Module author via `nameOverride` in `components.cue`; can be exposed in `#config` for end-user control | Keeps module portability; release author does not need a separate override mechanism for the common case | Release-author override via `ModuleRelease.values` — deferred to future scope |
| Override granularity | Component-level base name only | Covers the primary use case; sub-resource names (secret, ConfigMap, PVC) are derived from the base and propagate automatically | Per-resource sub-name overrides — deferred |
| Override semantics | Full K8s base name — release prefix is not added automatically when override is set | Maximum flexibility; author controls the full name and can make it environment-stable | Component-segment-only override (release prefix always prepended) — rejected: too restrictive; defeats the purpose for cross-component references |
| Cross-module references | Not in scope (v1) | Adds significant complexity; within-module covers all known use cases | Cross-module binding system — deferred |
| Name resolution mechanism | `#resolvedNames` map in `#TransformerContext`, computed once in Go before the transformer loop | Follows the existing context injection pattern; no CUE-layer orchestration needed; single computation site | CUE-layer lookup via an explicit `#componentRef` type — more complex, requires new CUE primitives, deferred |
| Cross-component reference at module level | CUE struct cross-reference (`#components.sibling.metadata.nameOverride`) | CUE-native; resolves at definition time without runtime lookup; no new concepts for module authors | New `#componentRef` helper wrapping a string key — adds indirection without benefit when the CUE struct is already in scope |
| Immutability hash | Always appended after name resolution, regardless of override | Correctness invariant; override must not skip cache invalidation behavior | Allow override to disable hash — rejected: breaks immutability guarantees |
| Backward compatibility | Default behavior (`{release}-{component}`) is unchanged when `nameOverride` is absent | Zero migration cost for all existing modules | Require opt-in rename of all existing resources — rejected: breaks existing deployments and Kubernetes ownership |
| Helper location | New file `catalog/opm/v1alpha1/schemas/resource_name.cue` | Consistent with existing `schemas/` pattern for shared CUE utilities; importable by all transformer packages | Inline per-transformer — perpetuates the convention-consensus problem this design is solving |
| `injectContext` signature change | Add `resolvedNames map[string]string` parameter | Explicit data flow; no global state; consistent with how other context fields are passed | Store in a struct field on the executor — less clear call-site traceability |
