# Notes and Deferred Discussions

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Purpose

This file collects every item that was explicitly flagged during the design process as requiring further discussion, follow-up design work, or implementation consideration before the feature can be considered complete. Items here are not blockers for the initial implementation unless otherwise noted.

---

## N1: Context Field Overrides — RESOLVED

**Noted during:** Design session, clarifying question 4.

**Resolution:** Resource name override is now part of this design. `#Component.metadata` gains an optional `resourceName` field. `#ContextBuilder` reads it when iterating components and passes it into `#ComponentNames`, where CUE unification replaces the default `"{release}-{component}"`. All DNS variants cascade automatically. See `03-schema.md` for the schema changes.

This supersedes the separate `002-resource-name-override` enhancement — the override mechanism lives entirely within the `#ctx` design and requires no additional schema constructs, Go pipeline changes, or transformer migration. See D13 in this design for the authoritative decision record.

---

## N2: `#TransformerContext` Migration

**Noted during:** Design session; recorded in `05-decisions.md` as a deferred decision.

**Note:** `#ctx` and `#TransformerContext` now overlap in several areas: release name, namespace, component name, and label computation exist in both. The two are currently kept separate — `#TransformerContext` is transformer-only, injected by Go via `FillPath`; `#ctx` is module-wide, computed in CUE.

**Why this matters:** Having two partially-overlapping context objects increases surface area for drift. Module authors will see `#ctx` at the module level and `#TransformerContext` inside transformers and may expect them to be consistent, but they are computed independently. A divergence in naming or value (e.g., `resourceName` vs `name`) would be confusing.

**What needs to happen:** A separate design must decide one of:

- Replace `#TransformerContext` with `#ctx` (transformers read from the module-level context)
- Extend `#TransformerContext` to embed or reference `#ctx.runtime`
- Keep them separate but establish an explicit consistency contract and shared source

This discussion should happen before `#ctx` is widely adopted in transformers, to avoid locking in an integration pattern that the migration would need to undo. See D15 in this design for the authoritative decision record.

---

## N3: Bundle-Level Context

**Noted during:** Design session; recorded in `README.md` Open Questions.

**Note:** This design establishes context at the module level only. There is no mechanism for one module to reference another module's computed names or DNS addresses. In a `#BundleRelease` that deploys multiple modules, cross-module references (e.g., module A's service URL referenced in module B's config) still require manual hardcoding or explicit `#config` values.

**Why this matters:** Platform teams composing bundles frequently need cross-module wiring. Without a bundle-level context scope, each module remains isolated and operators must repeat or pre-compute shared values by hand.

**What needs to happen:** A follow-up design for `#BundleRelease` context should consider:

- Whether `#BundleRelease` computes a shared `#bundleCtx` from all member module contexts
- How a module declares that it consumes another module's context
- Whether cross-module references are resolved at CUE evaluation time or at Go render time

This is explicitly out of scope for the current design and must not be retrofitted into `#ModuleContext` without a dedicated design.

---

## N4: `platform` Extension Namespacing

**Noted during:** Design session; recorded in `05-decisions.md` decision row for `platform` extension shape.

**Note:** The `platform` layer is currently a flat open struct (`{ ... }`). Platform teams add fields directly without any key convention, for example `platform: { myOrgTenantId: "..." }`. This is intentional for simplicity at this stage, but it creates no guardrails against key collisions between different platform teams or tooling integrations.

**Why this matters:** As more platform teams adopt `#ctx.platform`, uncoordinated key growth will make the struct opaque and hard to audit. Two teams adding `clusterId` to mean different things would silently unify in CUE.

**What needs to happen:** When the first concrete platform extension patterns are known, consider whether to introduce a namespacing convention (e.g., `platform: { myorg: { ... } }`) or a typed extension registry. The current flat struct is a valid starting point and does not need to change until actual collision risk materialises.

---

## N5: Two-Pass CUE Evaluation for Content Hashes (Strategy A)

**Noted during:** `04-pipeline-changes.md` content hash injection strategy discussion.

**Note:** Strategy B (Go-side hash injection after spec resolution) was chosen for the initial implementation. Strategy A (two-pass CUE evaluation where the first pass resolves specs and the second injects hashes back into `#ctx`) was considered but deferred.

**Why this matters:** Strategy B requires Go to be aware of which components produce hashes and how to inject them. If a module author wants to use `#ctx.runtime.components[name].hashes` to make decisions about their own component specs (not just to annotate pods), Strategy B cannot support that use case — Go resolves the spec first, hashes second, so the spec cannot depend on the hash.

**What needs to happen:** If a concrete use case emerges where a component spec must reference its own content hash before rendering (self-referential), revisit Strategy A. The two-pass approach is technically feasible but adds CUE evaluation complexity. Until such a use case exists, Strategy B is sufficient.

---

## N6: `#ctx` Override Propagation to Release Files — RESOLVED

**Noted during:** Post-design review of the `#environment` field placement.

**Resolution:** The `#Environment` import mechanism solves this. Each environment is defined in `.opm/environments/<env>/environment.cue` and imported by release files via `#env: env.#Environment`. Changing `clusterDomain` or `routeDomain` for a cluster requires updating only the `#Platform` or `#Environment` definition — all release files importing that environment pick up the change automatically via CUE's import mechanism. The shared environment profile pattern described below is now the default behavior, not a future aspiration.

**Note:** Platform operators supply `#environment` fields in `#ModuleRelease` today. If a future cluster migration changes `clusterDomain` or `routeDomain`, every release file referencing that cluster must be updated. There is currently no mechanism for a shared environment profile to be imported across all releases in a cluster.

**Why this matters:** In large-scale deployments with many `#ModuleRelease` files per cluster, updating `#environment` in one place for all releases is operationally important.

**What needs to happen:** Consider whether `releases/` should support an environment profile CUE file (e.g., `releases/<env>/environment.cue`) that all module releases in that environment import and unify with. This is a `releases/` repo concern and should be tracked there, but the `#environment` schema must remain compatible with that pattern.
