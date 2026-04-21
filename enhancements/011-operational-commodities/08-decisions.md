# Design Decisions

## D1 — Operational commodity contracts expressed via `#Trait` + `#Directive`

**Decision.** Backup is modeled as a `#Trait` (component-local facts) plus a `#Directive` (module-level orchestration) plus a `#PolicyTransformer` (render logic).

**Rationale.** Operational commodities require two distinct authoring layers: per-component facts ("back up my `config` volume; `CHECKPOINT` first") and module-level orchestration ("nightly, to offsite-b2, keep 7/4/3"). Mapping each layer to an existing primitive kind (`#Trait` for the first, `#Directive` inside `#Policy` for the second) is minimal and legible. No new component-level primitive is needed.

**Alternatives considered.**

- Put everything on the component via `#Trait`. Rejected: module-level facts (schedule, backend, retention) replicate across every participating component; authoring shape misrepresents cardinality.
- Introduce a dedicated `#Operation` primitive. Rejected: over-constrains; `#Directive` inside `#Policy` already fits, and a new primitive would need to justify itself against every future commodity.

## D2 — `#Directive` primitive introduced

**Decision.** Add `#Directive` under `catalog/core/v1alpha1/primitives/directive.cue`. Shape parallels `#Rule`.

**Rationale.** `#Policy` already carries `#Rule` for platform → module governance. The module → platform direction — "author instructs the platform" — has no existing home. `#Directive` fills that slot with the same structural shape as `#Rule`, differing only in direction and audience.

**Alternatives considered.**

- Merge `#Rule` + `#Directive` into a single type with a direction field. Rejected: the two have different authoring audiences (platform team vs. module author) and different enforcement semantics (governance vs. instruction). Typing them separately is clearer.
- Author directives as free-form CUE structs inside `#Policy` without a primitive wrapper. Rejected: gives up FQN-based identity, version pairing, and matcher ergonomics that every other primitive enjoys.

## D3 — `#Policy` broadened with `#rules` + `#directives`

**Decision.** `#Policy` carries both a `#rules` map and a `#directives` map. `spec` merges both. One policy can carry rules only, directives only, or both, with a shared `appliesTo`.

**Rationale.** `appliesTo` is a natural scoping mechanism that both rules and directives share. A module author writing "for these components, governance X AND instruction Y" can express both in one policy.

**Alternatives considered.**

- Split into `#RulePolicy` + `#DirectivePolicy`. Rejected: duplicates `appliesTo` semantics; awkward when a rule and a directive target the same component set.

## D4 — `#PolicyTransformer` is a distinct transformer scope

**Decision.** Add `#PolicyTransformer` alongside `#Transformer`. It matches a directive, reads the covered components' traits, and emits module-scope resources.

**Rationale.** The scope difference is real and unavoidable. Backup emits one K8up `Schedule` CR per policy, not per component. Forcing it into the component scope either (a) produces duplicate Schedule CRs that have to be de-duplicated later, or (b) inflates every workload trait-match with policy-lookup logic. Neither is honest.

**Alternatives considered.**

- **Option Q (from brainstorm):** Component-scope transformer with policy lookup. Rejected: misrepresents the output cardinality; policy lookup from within a per-component transformer is architectural drift.
- **Option R (from brainstorm):** Unify the directive's spec into each component's spec before rendering. Rejected: generates per-component duplicates that must be merged at render time; obscures module-scope intent.
- Add the capability under the existing `#Transformer` with a `scope: "component" | "policy"` discriminator. Rejected: the input shape differs enough (one vs. many components) that a union type is more confusion than reuse.

## D5 — Traits carry component-local facts only; cross-component concerns go in directives

**Decision.** `#BackupTrait` holds targets + hooks + include/exclude. `#BackupPolicy` holds schedule + backend + retention + restore. No cross-member.

**Rationale.** The split mirrors how real backup systems (Restic, K8up, Velero) carve concerns: per-app selectors vs. per-repo schedule/retention. Authoring that reflects this carving is more legible. It also prevents the "which component's schedule wins?" ambiguity if schedules were per-component.

**Alternatives considered.**

- Trait carries everything, including schedule/backend/retention. Rejected: forces per-component duplication of module-level facts.
- Directive carries everything, trait merely opts in. Rejected: loses the natural place for app-specific quiescing hooks, which genuinely are per-component.

## D6 — Backup backend resolved via `#Platform.#ctx.platform.backup.backends` for v1

**Decision.** `#BackupPolicy.backend` names a key in `#Platform.#ctx.platform.backup.backends`. The render pipeline resolves it at render time. Schema of each backend entry is defined by the K8up provider (or whichever provider owns the backup transformer).

**Rationale.** Platform ctx is already a well-formed home for platform-team-defined defaults. The `platform` layer is an open struct; this uses it as designed. No new resource type required for v1.

**Alternatives considered.**

- A first-class `#BackupBackend` resource. Rejected for v1: schema not stable enough; adds a resource type that would only be authored once per platform.
- Reference backends by label selector on cluster-level secrets. Rejected: conflates identity with credentials; harder to validate at render time.

**Future trigger.** Promote to a first-class resource if (a) the backend schema grows beyond a handful of fields, (b) multiple providers need to share the same backend configuration, or (c) backend definitions need their own lifecycle (rotation, audit).

## D7 — One `#BackupPolicy` per component (enforced at compile time)

**Decision.** A component may be covered by at most one `#BackupPolicy` directive across all policies in the module. Violation is a catalog-validation error.

**Rationale.** Merge semantics for overlapping schedules, retentions, or backends are undefined. Erring at compile time is cheap and forces the author to pick one.

**Alternatives considered.**

- Allow multiple with explicit merge rules. Rejected: introduces per-directive-kind merge logic that has no obvious correct answer (which schedule "wins"?).
- Allow multiple but require disjoint tag sets or disjoint volumes. Rejected: adds a new invariant to check, solves a small set of use cases we haven't seen yet.

**Future trigger.** Revisit if tiered backup (daily cheap + hourly expensive on same data) or dual-destination backup (local fast-restore + offsite DR) becomes a common authoring pattern. See [OQ-1](09-open-questions.md).

## D8 — Version pairing via shared CUE package + transformer match constraints

**Decision.** `#BackupTrait` and `#BackupPolicy` live in the same CUE package at `opmodel.dev/opm/v1alpha1/operations/backup@v1`. The K8up transformer declares both FQNs in its match predicate. No explicit `pairsWith` field on `#Trait` / `#Directive`.

**Rationale.** Co-located authoring is the simplest mechanism; a single import fixes both versions. The transformer's match predicate catches cases where someone imports from misaligned versions — a loud render-time failure rather than a silent inconsistency.

**Alternatives considered.**

- Explicit `pairsWith: [FQN]` field on both sides. Rejected for v1: adds schema noise; a catch that has never fired in practice to our knowledge.
- Version range satisfaction with fallback. Rejected: complicates match rules substantially for marginal benefit.

**Future trigger.** Add `pairsWith` if misalignment ever happens in practice and the render-time error is judged too late. See [OQ-2](09-open-questions.md).

## D9 — Restore procedure is declarative in the directive; snapshot selector is imperative (CLI)

**Decision.** `#BackupPolicy.restore` declares the restore workflow: pre/post steps, health checks, in-place behavior, DR flag. No snapshot selector in the directive. Snapshot is always a CLI argument.

**Rationale.** The workflow is a property of the application (what to scale down, how to probe) and does not change per restore event. The snapshot is the per-event input. Mixing them would force the author to re-edit the module every time they restore.

**Alternatives considered.**

- Default selector (e.g., `latest`) in the directive, overridable by CLI. Rejected: invites "forgotten default" bugs (restore uses stale default when operator forgot `--snapshot`).
- No restore in the directive; CLI reads from a separate file. Rejected: splits authoring of a single commodity into two places.

## D10 — Backend resolution failures surface at render, not at catalog compile

**Decision.** Missing `backend` names in `#Platform.#ctx.platform.backup.backends` error out at render time, not when the module is validated at catalog level.

**Rationale.** The module and the platform are authored in separate repos at separate times. Module-side validation cannot see the platform's backend inventory. Render is the first point both are in scope.

**Alternatives considered.**

- Ship a `catalog/modules/<mod>/platform-expectations.cue` file that the platform must satisfy. Rejected: heavy; adds a meta-layer that duplicates what render-time validation already does.

## D11 — Annotation-based provenance on policy-pass resources

**Decision.** Every resource emitted by a policy transformer is annotated with three mandatory annotations:

- `opm.opmodel.dev/owner-policy: <policy-name>`
- `opm.opmodel.dev/owner-directive: <directive-fqn>`
- `opm.opmodel.dev/owner-transformer: <transformer-fqn>`

A fourth annotation is optional:

- `opm.opmodel.dev/owner-component: <component-name>` — present when the emitting transformer's output is genuinely per-component (e.g., cert-manager `Certificate` CR, Prometheus `ServiceMonitor`). Absent when output is module-scope (e.g., backup `Schedule` CR covering many components). The emitting transformer decides.

**Rationale.** The three mandatory annotations enable diagnostics (tracing a broken CR back to its directive), diffing (clear delta ownership), and forward-compat. The optional fourth extends attribution to per-component output when the transformer naturally emits one resource per covered component — trace a failing `Certificate` for `web` back to the `web` component, not just to "the policy."

**Alternatives considered.**

- Only the three mandatory annotations; no component-level attribution. Rejected: for transformers that emit N resources per policy (one per covered component), the operator loses the ability to see which component a given output belongs to without inspecting the resource name.
- Mandate `owner-component` on every resource. Rejected: for genuinely module-scope output (backup's single `Schedule` covering many components), a single `owner-component` value would be fiction.
- Rely on `appliesTo` component labels only. Rejected: under-specified; multiple directives can have the same `appliesTo`.

## D12 — Policy-pass runs after component-pass, before merge; no feedback loop

**Decision.** Policy transformers cannot read component transformer output, and component transformers cannot read policy transformer output. The passes run in fixed order with no feedback.

**Rationale.** A directed pass order keeps the render semantics tractable and the mental model small. The rare case of "policy output informs component output" can always be rewritten as "introduce a trait that captures the needed fact at the component level."

**Alternatives considered.**

- Fixpoint iteration until stable. Rejected: non-determinism risk; slow; no concrete use case justifies the complexity.

## D13 — Policy transformer output is module-scope by default; optional per-component attribution via annotation

**Decision.** A `#PolicyTransformer` emits a map of `(kind, name) → manifest`. The pipeline does not *require* attribution of individual emitted resources to a specific covered component. A transformer *may* attribute individual resources via the optional `opm.opmodel.dev/owner-component` annotation (see D11) when its output is genuinely per-component.

**Rationale.** Both cardinalities are real:

- **Module-scope, single-output commodities** (backup: one `Schedule` CR per policy covering many components). Per-component attribution is fiction; no annotation.
- **Module-scope, per-component output commodities** (TLS: one `Certificate` CR per covered component). Per-component attribution is accurate and useful for diagnostics; annotation is present.

Keeping attribution optional lets each transformer express what is honestly true about its own output cardinality.

**Alternatives considered.**

- Require every transformer output to carry a `component` name. Rejected: forces a lie for module-scope output.
- Reject per-component output entirely; force module-scope single-output. Rejected: misrepresents commodities like TLS that naturally emit per-component resources.
- Introduce a distinct `#PerComponentPolicyTransformer` scope for per-component output. Rejected: the input shape is identical; differing only in output cardinality doesn't justify a new type. One transformer scope can cover both.

## D14 — `#ctx.platform.<commodity>.*` namespacing convention

**Decision.** Each operational commodity claims a top-level subtree under `#Platform.#ctx.platform` named after the commodity (matching the suffix of the commodity's directive `metadata.modulePath`). Commodities declare their reads via `#PolicyTransformer.readsContext` using paths under that subtree. The render pipeline validates path presence at render time.

**Rationale.** Three commodities (backup, TLS, routing) already use this shape:

- `#ctx.platform.backup.backends` — K8up repository configs.
- `#ctx.platform.tls.issuers` — cert-manager Issuer refs.
- `#ctx.platform.routing.gateways` — Gateway API Gateways.

Without a convention, each commodity would invent its own path layout, leading to collisions, inconsistency, and unpredictable `readsContext` strings. Codifying the convention gives:

- Discoverability — a platform team can list installed commodities and derive which `#ctx.platform` subtrees they need to populate.
- Collision prevention — each commodity owns one named subtree; conflicts surface at the convention level, not at render time.
- Predictable CLI diagnostics — `opm release diff` can map a missing path directly to the commodity that requires it.

**Alternatives considered.**

- Add a schema constraint to `#Platform.#ctx.platform` that validates known commodity subtrees. Rejected: couples the Platform schema to the set of installed commodities; the openness of `#ctx.platform` (per 008) is deliberate. Keep the convention advisory.
- Give each commodity a dedicated first-class resource instead of a `#ctx.platform` subtree. Deferred — see [OQ-3](09-open-questions.md) for when this graduation is warranted.
- Let commodity authors pick any subtree name they want. Rejected: authors would invent inconsistent names; reviewers would have no basis for rejection.

**Not enforced by schema.** The convention is documented and reviewed, not CUE-constrained. Commodities that violate it are still functional; they are merely awkward and will be flagged in review.
