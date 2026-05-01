# Design Decisions — `#Platform` Construct

## Summary

Decision log for all architectural and design choices made during this enhancement. Each decision is numbered sequentially and recorded as it is made. Decisions are append-only — do not remove or renumber existing entries. If a decision is reversed, add a new decision that supersedes it.

---

## Decisions

### D1: `#Platform` drops `#providers`; `#registry` of `#Module` values is the sole composition ingress

**Decision:** `#Platform` no longer has a `#providers: [...provider.#Provider]` field. The composition unit is `#Module`, registered through a single map field `#registry: [Id=string]: #ModuleRegistration`.

**Alternatives considered:**

- Keep `#providers` alongside `#registry` — accepts both ingress paths. Rejected: forces every ecosystem participant to ship both forms or accept partial discoverability; perpetuates the duplication described in 01-problem.md.
- Replace `#providers` only with a flat `[Id=string]: #Module` map (no `#ModuleRegistration` wrapper) — simpler shape but loses the enable flag, presentation metadata, and optional release reference that runtime tooling needs.

**Rationale:** Enhancement 015 made `#Module` the ecosystem extension unit. `#defines.transformers` makes `#Module` structurally equivalent to `#Provider` for transformer-registration purposes, while also carrying `#defines.{resources,traits,claims}`, `#components`, and `#claims` that `#Provider` cannot. A single ingress eliminates the duplication and gives every Module slot a platform-level home.

**Source:** User decision 2026-04-30 ("I don't want #providers directly in #Platform. I want it to be extremely dynamic").

---

### D2: `#registry` is fillable from both static (CUE) and runtime sources via the same schema field

**Decision:** `#registry` is declared as a normal CUE field. Platform CUE files write entries directly. The runtime fills additional entries via `FillPath`. CUE unification merges the two sources by Id key.

**Alternatives considered:**

- Two separate fields: `#registry` (static) + `#discoveredRegistry` (runtime). Rejected: forces every computed view to walk both maps and adds a precedence rule with no benefit — unification already handles the merge cleanly.
- Runtime-only: `#registry` is filled exclusively at runtime, platform CUE file uses an indirection (e.g. import a generated file). Rejected: prevents admins from declaring statically-known registrations (OPM core, K8up) at authoring time and breaks self-describing distribution (Constitution VIII).

**Rationale:** A single field with two write paths is the minimum viable schema. The runtime-fill mechanism (Strategy B–style, mirroring 008's content-hash injection) is deferred to a follow-up enhancement; this enhancement only needs the schema to permit both write paths.

**Source:** User decision 2026-04-30 ("extremely dynamic"); implementation pattern derived from 008 D12.

---

### D3: FQN collisions across registered Modules surface as CUE unification errors

**Decision:** When two registered Modules declare a definition under the same FQN (`#defines.resources`, `#defines.traits`, `#defines.claims`, or `#defines.transformers`), the platform's computed view fails CUE unification.

**Alternatives considered:**

- First-write-wins (preserve the first registered Module's value) — silently masks the conflict.
- Last-write-wins — order-dependent and surprising under dynamic registry fills.
- List of values per FQN — punts the resolution to consumers and breaks the keyed-map contract used by the matcher.

**Rationale:** FQN is constructed from `modulePath/name@version`. Two values under the same FQN means two ecosystem participants disagree on the type's shape — a genuine conflict that must be resolved by the admin (disable one registration, pin a different version, file an upstream issue). Failing loud at platform-evaluation time is correct behaviour. Consistent with 008 D18's treatment of provider FQN collisions.

**Source:** Design discussion 2026-04-30; precedent in 008 D18.

---

### D4: `#provider` is synthesised internally from `#composedTransformers` *(superseded by D12)*

**Decision:** `#Platform` exposes a `#provider: provider.#Provider` field whose `#transformers` map is `#composedTransformers`. Metadata is filled from the platform's own identity. The matcher reads this synthetic provider unchanged.

**Alternatives considered:**

- Remove `#Provider` entirely and update the matcher to consume `#composedTransformers` directly. Rejected for now: changes the matcher signature and Go pipeline interface; out of scope for a thin platform-construct enhancement.
- Reify `#Provider` as a first-class concept on `#Platform`. Rejected: re-introduces the duplication that D1 eliminated.

**Rationale:** Internal compatibility shim. `#Provider` survives as a transport type the matcher expects; the platform constructs it on demand without exposing it as a composition surface. Future enhancement may dissolve `#Provider` entirely once the matcher is migrated.

**Status:** Superseded by **D12** (2026-05-01). `#Provider` retired entirely; matcher consumes `#composedTransformers` + the new `#matchers` reverse index directly.

**Source:** Design discussion 2026-04-30.

---

### D5: `#registry` value type is `#ModuleRegistration`, not bare `#Module` *(narrowed by D11)*

**Decision:** Each `#registry` entry wraps a `#Module` in a `#ModuleRegistration` struct that adds `enabled` (default `true`) and `presentation?` fields.

**Alternatives considered:**

- Bare `[Id=string]: module.#Module`. Rejected: gives admins no way to disable a registration without removing it, and no place for platform-level curation metadata (self-service catalog category/tags/examples).
- Two parallel maps — one for Modules, one for registration metadata. Rejected: keeps related fields apart and complicates runtime fills.

**Rationale:** The wrapper carries platform-level metadata that is *about* the registration, not about the Module itself. The Module value is referenced via `#module`; everything else describes how the platform handles it.

**Status:** Narrowed by **D11** (2026-05-01). The original draft also carried `#release?` (deploy-state assertion) and `presentation.operator` (admin-facing install metadata); both removed because registration is now a pure projection of `#defines`. Deploy state lives in the `ModuleRelease` CRD reconciler, not in the CUE registration value.

**Source:** Design discussion 2026-04-30.

---

### D6: `#PolicyTransformer` registration is deferred

**Decision:** `#defines.transformers` is typed as `transformer.#Transformer` only (not `transformer.#Transformer | transformer.#PolicyTransformer`). Policy-scope transformers are not registered through the platform until the policy redesign (enhancement 012) converges.

**Alternatives considered:**

- Include `#PolicyTransformer` in the union now. Rejected: 012 is still in exploration phase and may revise the policy model in ways that change `#PolicyTransformer`'s shape or eliminate it entirely. Including it now risks committing to a shape we are about to change.

**Rationale:** Keep the platform construct thin and unblocked by the open policy work. When the policy redesign settles, a follow-up enhancement adds `#PolicyTransformer` (or its successor) to the platform's view in a single contained change.

**Source:** User decision 2026-04-30 ("Remove #PolicyTransformer for now. i want to figure out a better way to handle policies").

---

### D7: Capability fulfilment is registered via transformer `requiredClaims`; no separate `#apis` aggregation

**Decision:** Capability fulfilment for `#Claim` requests is registered by the transformer that does the rendering, via the transformer's `requiredClaims` field (introduced in 015). `#Platform` exposes `#composedTransformers` only; there is no separate `#apis` aggregation map keyed by Claim FQN. A consumer Module's `#claims` instance is matched at deploy time by the platform's render pipeline against transformers whose `requiredClaims` include the Claim's FQN.

**Alternatives considered:**

- Aggregate `#apis: [fqn=string]: prim.#Api` from each registered Module's `#apis` slot. Rejected: 015 CL-D14 removes the `#Api` primitive entirely. Capability supply is now expressed through the transformer that renders the request, not a wrapper primitive.
- List-of-implementations map keyed by Claim FQN, derived from transformer `requiredClaims`. Rejected for now: pre-emptively encodes a resolution policy. The matcher already iterates `#composedTransformers` per component; the same iteration can resolve Claim requests without an extra projection. Multi-fulfiller resolution policy is deferred to a follow-up (see OQ5).

**Rationale:** Removing `#Api` from 015 makes a Platform-level `#apis` view redundant. The transformer is both the renderer and the registration; aggregating that information twice (once as transformers, once as `#apis`) duplicates state. Keep the platform's outward views minimal; let the matcher discover fulfillers by walking `#composedTransformers`.

**Source:** User decision 2026-04-30 ("Now i want to remove #Api definition"). Replaces an earlier formulation that aggregated `#apis` from `#Module.#apis`; that formulation was edited in place (014 was unimplemented) rather than appended as a superseding decision.

---

### D8: Platform compatibility detection is the matcher's job; no `#requires` field on `#Module`

**Decision:** A consumer Module declares no platform compatibility. At deploy time the matcher walks the module body for FQN usage — Resource and Trait FQNs from `#components[].#resources` / `#components[].#traits`, Claim FQNs from `#claims` (module-level) and `#components[].#claims` (component-level) — and looks each up in `#composedTransformers`. Unmatched FQNs are surfaced as a platform-level signal. The module schema gains nothing — `#Module` stays at 8 slots (see 015 MS-D5).

What to do about unmatched FQNs (fail / warn / drop, possibly with per-FQN `criticality` hints on Resource / Trait / Claim definitions) is a separate **platform-team policy** concern that lives at the platform level. That policy is deferred until the catalog `#Policy` redesign (012) converges — detection (this decision) and response (deferred) are independent.

**Alternatives considered:**

- **`#Module.#requires.platformType: "kubernetes" | …`** — declarative platform-type pinning. Rejected: forces module authors to predict every target the module might one day deploy to; the platform already knows what it supports.
- **`#Module.#requires.resourceTypes: [...FQN]`** — declarative resource-type requirements. Rejected: duplicates information already present in `#components[].#resources`; the matcher derives the same set automatically.
- **Per-Resource `criticality` hints** (`must` / `should` / `nice`) shipped on the type definition. Considered. Deferred — pairs naturally with the platform-level matching policy that's also deferred.

**Rationale:** The matcher already walks an FQN graph derived from the module body. A parallel `#requires` declaration creates two sources of truth ("module body says X is used"; "module declares it requires X") that drift. Trusting the matcher keeps the module schema minimal and aligns with D7's "transformer presence is the registration" principle: capability supply = transformer FQN match-keys; capability demand = module-body FQN reads. Symmetric, mechanical, no module-author bookkeeping.

**Cross-references:** 015 MS-D5 (no `#requires` slot on `#Module`); 016 D29 (k8s vocabulary canonical, non-k8s runtimes derive — relies on this matcher mechanism for unmatched detection); D7 (Claim fulfilment via transformer `requiredClaims`); D3 (FQN identity used by the matcher).

**Source:** User decision 2026-05-01 ("I would like for the platform runtime implementation to be responsible for figuring this out").

---

### D9: Non-Kubernetes runtime support is achieved via per-runtime transformer Modules

**Decision:** A non-Kubernetes runtime (Docker Compose, HashiCorp Nomad, future targets) is realised as a `#Module` registered in `#Platform.#registry` whose `#defines.transformers` emit target-specific output for the same k8s-vocabulary Resource / Trait / Claim FQNs that other Modules use. Module bodies are unchanged across runtimes — they read `#ctx.runtime.cluster.domain`, `#ctx.runtime.components.<x>.dns.svc`, etc. The non-k8s runtime Module's transformers map those k8s-shaped fields to local concepts (`namespace` → compose project, `dns.svc` → network alias, see 016 D29). Cross-runtime ecosystem-supplied resolutions (URLs, peer addresses, connection strings) flow through Claim `#status` (015 CL-D15), with each runtime registering its own fulfilling transformer for the relevant Claims.

Drops, warnings, and criticality policy for FQNs the non-k8s runtime cannot render are deferred — same as D8.

**Alternatives considered:**

- **Generic `#ctx.runtime` field shapes** (`searchDomain` instead of `cluster.domain` etc.). Rejected by 016 D29 — produces lowest-common-denominator field names without earning real portability; non-k8s runtimes can map k8s vocabulary mechanically.
- **Per-target subtree split inside `#ctx.runtime`.** Rejected by 016 D30 — would force module bodies to do target-specific reads.
- **YAML-to-YAML translator** (k8s pipeline runs first, produces YAML; compose translator parses it and emits compose YAML). Rejected: bypasses the catalog's transformer architecture; a translator can't access semantic info that a transformer-pipeline can. The same architecture (transformer Modules in `#registry`) handles every runtime.

**Rationale:** A new runtime needs the same primitives as k8s — Resource definitions, Trait definitions, Claim definitions, transformers. The cleanest place for those is a `#Module` with full `#defines`. `#registry` is already the dynamic ingress (D1, D2); adding a compose-runtime Module is the same operation as adding any other transformer-shipping Module. No special-case translator pipeline; no separate runtime-registration channel. Symmetry.

**Cross-references:** 016 D29 (k8s vocabulary canonical); 016 D30 (no `target.<runtime>` split); 015 CL-D15 (Claim `#status` as cross-runtime resolution surface); D1 / D2 (registry as the sole composition ingress).

**Source:** Design conversation 2026-05-01 (platform-model brainstorm).

---

### D10: `#Blueprint` has no platform-level publication or aggregation

**Decision:** `#Platform` exposes no `#knownBlueprints` view. `#Module.#defines` drops the `blueprints` sub-map (paired drop in 015 DEF-D6). `#Blueprint` definitions remain plain CUE types developers import from their declaring packages; the platform never aggregates them.

**Alternatives considered:**

- **Keep `#knownBlueprints` for symmetry with `#knownResources` / `#knownTraits` / `#knownClaims`.** Rejected: symmetry is the only argument. Blueprints have zero downstream consumer in the platform — the matcher walks Resource / Trait / Claim FQNs (transformer.cue `requiredResources` / `requiredTraits` / `requiredClaims`), never Blueprint FQNs. A `#known*` view with no consumer is dead schema.
- **Reshape Blueprints into `presentation.template`** (Blueprints surface only as golden-path templates on a `#ModuleRegistration`). Rejected: breaks the "all type definitions live under `#defines`" pattern without removing the underlying redundancy. If Blueprints are not platform-aggregated at all, the simpler cut is to remove the publication slot entirely.
- **Defer the cut, leave the schema as-is.** Rejected: 014 is unimplemented. Removing now is free; removing after release is a breaking change.

**Rationale:** Blueprint is a CUE composition of Resources + Traits + Claims. It has no runtime semantics — the matcher never matches against a Blueprint FQN, no transformer's `requiredResources` / `requiredTraits` / `requiredClaims` references one, and at deploy time a Blueprint's contribution has already expanded into the Component's `#resources` / `#traits` slots before render begins. The Component's `#blueprints` field stays (used for spec-field merging via `_allFields` in component.cue) but is internal to Component, not a platform-aggregation surface. Discovery for hypothetical tooling (`opm new <blueprint>`) can walk `#registry[*].#module` directly without a dedicated `#known*` field — same deferral pattern as OQ4.

Asymmetry with the other `#defines.*` slots is correct, not a flaw: Resources, Traits, and Claims earn their `#known*` views because the matcher reads them (Resources / Traits via transformer match keys; Claims via demand-side FQN walk + transformer `requiredClaims` supply registration — D7). Blueprints earn nothing.

**Cross-references:** 015 DEF-D6 (paired drop of `#defines.blueprints`); D7 (capability fulfilment via transformer `requiredClaims`, no separate `#apis` aggregation — same parsimony principle); D8 (matcher walks Resource / Trait / Claim FQNs only); core/v1alpha2/component.cue (Component retains `#blueprints` for spec merging).

**Source:** User decision 2026-05-01 ("I don't think we need to register the blueprints. A blueprint is just a composition of #Resources, #Traits, and #Claims" → Option E).

---

### D11: `#ModuleRegistration` is a pure projection of `#defines`; deployment is owned by `ModuleRelease` + `opm-operator`

**Decision:** `#ModuleRegistration` carries no install or deploy metadata. The registration value reflects "this Module's primitives (`#defines`) are visible on this platform" — nothing more. Installation of `#components` is an operator-driven step:

1. User creates a `ModuleRelease` CR referencing a Module (with `#defines` populated).
2. `opm-operator` reconciles the CR: installs `#components` against the cluster *and* `FillPath`s the Module value into `#Platform.#registry[id].#module`.
3. Registration and installation are a single operator-driven step; the CUE model does not carry separate "install instructions" or release-state assertions.

Concretely this drops two fields from D5's draft `#ModuleRegistration` shape:

- **`#release?: _`** — removed. Encoded cluster state in the CUE value, conflating two concerns. Cluster state lives in the `ModuleRelease` CRD reconciler; the registration only reflects the consequence of a successful reconcile.
- **`presentation.operator: { description?, installNotes? }`** — removed. `#module.metadata.description` already covers admin-facing copy; install notes belong in Module documentation, not in platform-level schema. The platform never needs to read "how to install" — the operator already has the full Module value.

`presentation.template` survives because it carries platform-curation data (category / tags / examples for self-service surfacing) that the Module itself cannot know — it is information about how *this platform* surfaces the Module, not about the Module.

**Alternatives considered:**

- **Keep `#release?` for static asserts.** Rejected: admins who want to assert "this Module is materialised" can write a `ModuleRelease` CR; they do not need a parallel CUE channel. Two channels = drift.
- **Keep `presentation.operator` for admin-facing install hints.** Rejected: install hints are documentation, not schema. Tooling that wants admin-facing help can read `#module.metadata.description` (or a future doc surface on `#Module`); the registration does not need its own copy.
- **Drop `presentation` entirely; let tooling derive everything from `#module.metadata`.** Considered. Rejected because per-platform curation (category / tag overrides for the same Module surfaced under different platforms) is a real need that the Module cannot pre-bake.

**Rationale:** Registration ≠ deployment. Conflating them creates two sources of truth (CUE registration value vs. live `ModuleRelease`) and forces every consumer to reconcile both. Pure projection — `#registry[id].#module` carries the Module value, the operator owns the install + the FillPath, and downstream views (`#knownResources`, `#composedTransformers`, …) recompute automatically. No install metadata in CUE.

**Cross-references:** D2 (registry fillable from static + runtime via the same field); D5 (narrowed by this decision); OQ1 (runtime-fill mechanism — `opm-operator` reconciler is the implementation path); OQ4 (self-service catalog runtime — consumes `presentation.template`).

**Source:** User decision 2026-05-01 ("we don't need ANY instructions for the operators. No install instructions. Installing the #Module as a ModuleRelease (with #defines defined) will automagically register the primitives").

---

### D12: Matcher logic lives on `#Platform` via `#matchers` + `#PlatformMatch`; `#Provider` retired

**Decision:** Replace the synthetic `#provider` (D4) with two native constructs in `core/v1alpha2/platform.cue`:

1. **`#Platform.#matchers`** — a computed reverse index over `#composedTransformers`. Three submaps (`resources`, `traits`, `claims`) each keyed by FQN; the value is the list of transformer candidates whose `required*` field includes that FQN. Resources and Traits index `#ComponentTransformer` only (CL-D11); Claims index the union of `#ComponentTransformer` and `#ModuleTransformer` (TR-D5).
2. **`#PlatformMatch`** — a per-deploy walker. Inputs: a `#Platform` and a consumer `#Module`. Outputs: `matched`, `unmatched`, and `ambiguous` projections that the Go pipeline / `opm-operator` consumes per render pass. `_demand` is computed from the consumer Module's component bodies (`#components[*].#resources/#traits/#claims`) and module-level `#claims`.

`#Provider` and the `provider.cue` file are deleted. The matcher Go interface migrates to read `#composedTransformers` and `#matchers` directly. `#declaredResources` and `#declaredTraits` (convenience FQN lists on `#Platform`) are also dropped — `#knownResources` / `#knownTraits` map keys give the same information.

**Alternatives considered:**

- **Keep `#provider` as a permanent compat shim** (status quo from D4). Rejected: shim survives only to preserve a Go interface that this enhancement is already changing; carrying it forward bakes in dead schema. Killing it now is a one-time cost vs. perpetual confusion about why a synthetic field exists.
- **Index transformers without exposing `#matchers`** (matcher Go code rebuilds the reverse index every render). Rejected: the index is a deterministic projection of `#composedTransformers`; CUE expresses it once, the Go pipeline reads it. Rebuilding per render duplicates work and hides the contract.
- **Make `#PlatformMatch` a method on `#Platform`** (no separate construct). Rejected: CUE definitions are not parameterised functions. A separate construct that takes `platform!` and `module!` is the clean expression of "instantiate a match per deploy".
- **Surface the render plan (matched transformer per FQN) directly instead of candidate lists.** Rejected: resolution policy (OQ5 — multi-fulfiller selection) is not yet decided; surfacing candidate lists keeps the schema honest and gives policy a place to plug in.

**Rationale:** D4 deferred the matcher migration as out-of-scope. With D11 simplifying `#ModuleRegistration` and the schema otherwise stabilising, deferring `#provider` removal trades short-term scope for long-term debt. The reverse index belongs to `#Platform` because it is a deterministic projection of the platform's transformer catalog. The per-deploy walker belongs alongside it because it operationalises D8 detection (unmatched FQNs) and exposes the OQ5 hook (ambiguous candidates) without committing to a resolution policy. Schema and Go pipeline land in lockstep; no window where the two disagree.

**Cross-references:** D4 (superseded); D7 (capability fulfilment via `requiredClaims` — `#matchers.claims` is the operationalisation); D8 (matcher detects unmatched FQNs — `#PlatformMatch.unmatched` is the surface); 015 TR-D5 (two transformer primitives — what the index keys against); OQ5 (multi-fulfiller resolution — `#PlatformMatch.ambiguous` is the hook).

**Source:** User decision 2026-05-01 ("Lets come up with a new set of definitions that work within the scope of #Platform. It should handle the matching logic").

---

## Open Questions

Captured here while the enhancement is thin (no separate `NN-open-questions.md` yet).

### OQ1 — Runtime-fill mechanism

`#registry` is declared as fillable from runtime, but the mechanism (Go-side `FillPath` versus CUE-side discovered-registry import versus operator CRD reconciliation) is not specified here. **Revisit trigger:** when the first runtime-fill source is implemented (likely `opm-operator/`).

### OQ2 — `#Platform.type` role beyond UX / registry filtering

D8 (matcher detects unmatched FQNs) subsumes the type-mismatch *detection* concern: a Module registered against the wrong runtime surfaces as unmatched FQNs at deploy time, with no need to consult `#Platform.type`. The remaining open question is whether `#Platform.type` still has a job — UX hints (catalog UIs filter "compatible Modules" by type), registry-filter shortcuts before walking FQNs, or a deprecated field. **Revisit trigger:** when self-service catalog tooling ships and we discover whether the field carries weight beyond display.

### OQ3 — Migration of existing provider packages

`opmodel.dev/opm/v1alpha2/providers/kubernetes`, `opmodel.dev/k8up/v1alpha2/providers/kubernetes`, `opmodel.dev/cert_manager/v1alpha2/providers/kubernetes` all currently export `#Provider` values. Each must be re-shaped as a `#Module` with the existing transformers under `#defines.transformers` (and OPM core gains the catalog of resources/traits under the rest of `#defines`). **Revisit trigger:** separate migration enhancement after this lands.

### OQ4 — Self-service catalog runtime API

`presentation.template` declares the metadata; the consuming surface (`opm catalog list`, web UI, deploy-time matcher) is platform-implementation territory. **Revisit trigger:** when the first self-service catalog tooling is implemented in `cli/` or `opm-operator/`. Consistent with 015 DEF-Q1.

### OQ5 — Conflict resolution when two transformers declare overlapping `requiredClaims`

Two registered Modules may each ship a transformer (`#ComponentTransformer` or `#ModuleTransformer`) whose `requiredClaims` includes the same Claim FQN (e.g. one Postgres operator and one Aiven operator, both fulfilling `ManagedDatabase`). The platform's render pipeline must pick one per consumer request. Candidates: admin-selected default fulfiller per Claim FQN, consumer-pinned fulfiller (transformer FQN), or registry priority order. **Revisit trigger:** first real conflict from two ecosystem participants. Same trigger as 015 TR-Q2.
