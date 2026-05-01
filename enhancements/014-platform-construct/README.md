# Design Package: `#Platform` Construct

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-30       |
| **Authors** | OPM Contributors |

## Summary

Defines `#Platform` as the catalog construct that models a deployment target. `#Platform` carries platform identity (`metadata`, `type`), platform-level context (`#ctx`, typed `#PlatformContext` from enhancement 016), and a single dynamic ingress — `#registry` — that holds registered `#Module` values. All outward platform-level views (known resources, traits, claims, composed transformers, matcher index) are computed projections over `#registry`.

`#Platform` does not carry a `#providers` field. `#Provider` is retired (D12); the matcher consumes `#composedTransformers` and the new `#matchers` reverse index directly. A companion `#PlatformMatch` construct walks a consumer Module's FQN demand against `#matchers` and surfaces `matched` / `unmatched` / `ambiguous` projections per deploy.

`#ModuleRegistration` is a pure projection of `#defines` — no install or deploy metadata (D11). Installation is owned by `ModuleRelease` + `opm-operator`: a release CR triggers component install *and* FillPath into `#registry`, registering the Module's primitives automatically.

This enhancement is intentionally thin. `#Environment`, runtime fill mechanism for `#registry`, self-service catalog runtime, `#PolicyTransformer` integration, multi-fulfiller resolution policy, and migration of existing provider packages are deferred to follow-up enhancements.

## Documents

1. [01-problem.md](01-problem.md) — 008's `#providers` list is a static composition point; no place for module-level extension surface (013's `#defines`); two parallel ingress concepts (Provider + Module)
2. [02-design.md](02-design.md) — `#Platform` shape with `#registry` as sole dynamic ingress; computed `#known*` views and `#matchers` reverse index; per-deploy `#PlatformMatch` walker; operator-driven registration via `ModuleRelease`
3. [03-schema.md](03-schema.md) — CUE definitions for `#Platform`, `#ModuleRegistration`, `#PlatformMatch`
4. [04-decisions.md](04-decisions.md) — Decision log

## Applicability Checklist

- [x] `03-schema.md` — New CUE definitions for `#Platform`, `#ModuleRegistration`, `#PlatformMatch`
- [ ] `NN-pipeline-changes.md` — Go pipeline modifications (deferred — covered by follow-up runtime-fill enhancement)
- [ ] `NN-module-integration.md` — Migration of existing provider packages (deferred — separate enhancement)
- [ ] `NN-notes.md` — Deferred items and open questions (folded into 04-decisions.md while thin)

## Scope

### In scope

- `#Platform` construct: identity, `type`, `#ctx` reference, `#registry`, computed views (`#knownResources`, `#knownTraits`, `#knownClaims`, `#composedTransformers`, `#matchers`).
- `#ModuleRegistration` schema (pure projection of `#defines`; no install metadata).
- `#PlatformMatch` construct — per-deploy walker producing `matched` / `unmatched` / `ambiguous` against the consumer Module's FQN demand.
- Static and runtime-fillable composition of `#registry` (runtime path: `opm-operator` reconciles `ModuleRelease` and FillPaths the Module value).
- Retirement of `#Provider` and the synthetic `#provider` shim — the matcher now consumes `#composedTransformers` + `#matchers` directly.

### Out of scope

- `#Environment` construct (008 — referenced unchanged).
- `#ctx` / `#PlatformContext` schema (008 — referenced unchanged).
- `#ContextBuilder` and module integration (008 — referenced unchanged).
- Runtime-fill mechanism (Strategy B–style Go injection) — declared in schema, mechanism in follow-up.
- Self-service catalog runtime API (`opm catalog list`, web UI, etc.).
- `#PolicyTransformer` registration (deferred — pending policy redesign).
- Migration of existing `opmodel.dev/opm/v1alpha2/providers/kubernetes` and other provider packages into `#Module` form.
- Conflict resolution when two registered Modules fulfil the same `#Claim` FQN.

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `CONSTITUTION.md` (repo root) | Core design principles governing all changes in this repository |
| `catalog/enhancements/archive/008-platform-construct/` | Archived predecessor — original `#Platform` construct with `#providers` list. This enhancement supersedes that schema. The `#ctx` / `#Environment` / `#ContextBuilder` portion of 008 is lifted into enhancement 016. |
| `catalog/enhancements/016-module-context/` | Sibling — defines `#PlatformContext`, `#EnvironmentContext`, `#ModuleContext`, `#ContextBuilder`, `#Environment`. `#Platform.#ctx` is typed by 016's `#PlatformContext`. |
| `catalog/enhancements/015-module-defines/` | Sibling — defines the flat `#Module` shape with `#defines` slot that this enhancement aggregates from |
| `catalog/enhancements/archive/011-operational-commodities/` | Archived — `#PolicyTransformer` registration on `#Platform` is deferred until policy redesign (012) lands |
| `catalog/enhancements/012-policy-redesign/` | Open exploration that will inform policy-layer integration |
| `catalog/core/v1alpha2/provider.cue` | `#Provider` — **retired in this enhancement** (D12). File deleted; matcher migrates to `#composedTransformers` + `#matchers`. |
| `catalog/core/v1alpha2/module.cue` | `#Module` — registered values flow through `#Platform.#registry` |
