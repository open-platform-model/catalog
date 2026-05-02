# Design Package: `#Platform` Construct

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-30       |
| **Authors** | OPM Contributors |

## Summary

Defines `#Platform` as the catalog construct that models a deployment target. `#Platform` carries platform identity (`metadata`, `type`), platform-level context (`#ctx`, typed `#PlatformContext` from enhancement 016), and a single dynamic ingress — `#registry` — that holds registered `#Module` values. Outward platform-level views at this layer (known resources, known traits, composed transformers, matcher index) are computed projections over `#registry`.

`#Platform` does not carry a `#providers` field. `#Provider` is retired (D12); the matcher consumes `#composedTransformers` and the new `#matchers` reverse index directly. A companion `#PlatformMatch` construct walks a consumer Module's FQN demand against `#matchers` and surfaces `matched` / `unmatched` / `ambiguous` projections per deploy. v1alpha1's single `#Transformer` is replaced by `#ComponentTransformer` (D17) — the sole transformer primitive at this layer; the runtime guarantees a fully concrete `#ModuleRelease` to every `#transform` body (D18).

`#ModuleRegistration` is a pure projection of `#defines` — no install or deploy metadata (D11). Installation is owned by `ModuleRelease` + `opm-operator`: a release CR triggers component install *and* FillPath into `#registry`, registering the Module's primitives automatically.

Multi-fulfiller is forbidden at the `#matchers` layer (D13) — overlapping `requiredResources` / `requiredTraits` FQNs across registered transformers fail platform evaluation rather than picking a winner. `#ModuleRegistration.enabled: false` hides every projection of an entry (D14). Concurrent static + runtime writes to the same Id unify; concrete-value disagreement is surfaced by the `opm-operator` reconciler in `ModuleRelease.status.conditions` (D15). Id keys are kebab-case (`#NameType`, D16). Schema is validated by the self-contained CUE harness at `catalog/experiments/002-platform-construct/`.

This enhancement is intentionally thin. `#Environment`, runtime-fill mechanism for `#registry`, self-service catalog runtime, `#PolicyTransformer` integration, multi-fulfiller resolution policy reopening, topo-sort algorithm for `#status` writeback ordering, and migration of existing provider packages are deferred to follow-up enhancements. `#Claim`, `#ModuleTransformer`, status writeback, and the Claim halves of every `#Platform` view are introduced as extensions in sibling enhancement [015](../015-claims/) — see Cross-References.

## Documents

1. [01-problem.md](01-problem.md) — 008's `#providers` list is a static composition point; no place for module-level extension surface (013's `#defines`); two parallel ingress concepts (Provider + Module)
2. [02-design.md](02-design.md) — `#Platform` shape with `#registry` as sole dynamic ingress; computed `#known*` views and `#matchers` reverse index (multi-fulfiller forbidden via `_invalid` constraint); per-deploy `#PlatformMatch` walker; operator-driven registration via `ModuleRelease`; concurrent-write conflict surface
3. [03-schema.md](03-schema.md) — CUE definitions for `#Platform`, `#ModuleRegistration`, `#PlatformMatch`, `#ComponentTransformer`, `#TransformerMap` with kebab-case Id constraint, `_invalid` projection, and component-scope demand walker
4. [04-decisions.md](04-decisions.md) — Decision log (D1–D18) + open questions (OQ5 closed by D13)
5. [05-component-transformer-and-matcher.md](05-component-transformer-and-matcher.md) — `#ComponentTransformer` design narrative, runtime guarantee (D18), matcher algorithm pseudocode, worked Deployment example, v1alpha1 → v1alpha2 migration impact

## Applicability Checklist

- [x] `03-schema.md` — CUE definitions for `#Platform`, `#ModuleRegistration`, `#PlatformMatch`, `#ComponentTransformer` (D1–D18 incorporated)
- [x] `04-decisions.md` — Decision log including D13–D18 (multi-fulfiller forbidden, enabled-hides, concurrent-write conflict, kebab Id, `#ComponentTransformer` redesign, runtime guarantee)
- [x] `05-component-transformer-and-matcher.md` — Transformer schema + matcher algorithm in one place
- [x] `catalog/experiments/002-platform-construct/` — Self-contained CUE harness validating every projection and constraint in `03-schema.md`
- [ ] `NN-pipeline-changes.md` — Go pipeline modifications (deferred — covered by follow-up runtime-fill enhancement; topo-sort algorithm is OQ6)
- [ ] `NN-module-integration.md` — Migration of existing provider packages (deferred — separate enhancement, OQ3)

## Scope

### In scope

- `#Platform` construct: identity, `type`, `#ctx` reference, `#registry`, computed views (`#knownResources`, `#knownTraits`, `#composedTransformers`, `#matchers.{resources, traits}`).
- `#ModuleRegistration` schema (pure projection of `#defines`; no install metadata).
- `#PlatformMatch` construct — per-deploy walker producing `matched` / `unmatched` / `ambiguous` against the consumer Module's Resource/Trait FQN demand.
- `#ComponentTransformer` schema and `#TransformerMap` — sole transformer primitive at this layer (D17).
- Matcher algorithm (component-scope fan-out) plus the runtime guarantee (D18).
- Static and runtime-fillable composition of `#registry` (runtime path: `opm-operator` reconciles `ModuleRelease` and FillPaths the Module value).
- Retirement of `#Provider` and the synthetic `#provider` shim — the matcher now consumes `#composedTransformers` + `#matchers` directly.

### Out of scope

- `#Environment` construct (016 — referenced from there).
- `#ctx` / `#PlatformContext` schema (016 — referenced from there).
- `#ContextBuilder` and module integration (016 — referenced from there).
- `#Claim` primitive, `#ModuleTransformer`, status writeback (`#statusWrites`), `#defines.claims`, `#knownClaims`, `#matchers.claims`, the Claim halves of `#PlatformMatch._demand` / `matched` / `unmatched` / `ambiguous` — all extensions in [015](../015-claims/).
- Runtime-fill mechanism (Strategy B–style Go injection) — declared in schema, mechanism in follow-up.
- Self-service catalog runtime API (`opm catalog list`, web UI, etc.).
- `#PolicyTransformer` registration (deferred — pending policy redesign).
- Migration of existing `opmodel.dev/opm/v1alpha2/providers/kubernetes` and other provider packages into `#Module` form.
- Multi-fulfiller resolution policy. Today: forbidden by D13 — failing platform-eval. Reopening requires a future enhancement with a deliberate selection mechanism.
- Topological-sort algorithm for `#status` writeback ordering — delegated to Go pipeline (OQ6).

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `CONSTITUTION.md` (repo root) | Core design principles governing all changes in this repository |
| `catalog/enhancements/archive/008-platform-construct/` | Archived predecessor — original `#Platform` construct with `#providers` list. This enhancement supersedes that schema. The `#ctx` / `#Environment` / `#ContextBuilder` portion of 008 is lifted into enhancement 016. |
| `catalog/enhancements/016-module-context/` | Sibling — defines `#PlatformContext`, `#EnvironmentContext`, `#ModuleContext`, `#ContextBuilder`, `#Environment`. `#Platform.#ctx` is typed by 016's `#PlatformContext`. |
| `catalog/enhancements/015-claims/` | Sibling — extends this enhancement with `#Claim` primitive, `#ModuleTransformer`, status writeback, and `#defines.claims` |
| `catalog/enhancements/archive/011-operational-commodities/` | Archived — `#PolicyTransformer` registration on `#Platform` is deferred until policy redesign (012) lands |
| `catalog/enhancements/012-policy-redesign/` | Open exploration that will inform policy-layer integration |
| `catalog/core/v1alpha2/provider.cue` | `#Provider` — **retired in this enhancement** (D12). File deleted; matcher migrates to `#composedTransformers` + `#matchers`. |
| `catalog/core/v1alpha2/transformer.cue` | `#ComponentTransformer`, `#TransformerMap` — introduced in this enhancement (D17). 015 extends with `#ModuleTransformer` and widens `#TransformerMap` to the union. |
| `catalog/core/v1alpha2/module.cue` | `#Module` — registered values flow through `#Platform.#registry` (Module shape introduced in 015) |
