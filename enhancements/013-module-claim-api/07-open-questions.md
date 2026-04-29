# Open Questions — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

Items that remain unresolved after the initial design conversation. Each entry is tagged with a category and includes a revisit trigger where applicable.

## Categories

- **Resolved-but-pending-implementation:** Decision is made (see `06-decisions.md`); implementation must answer specifics.
- **Genuinely open:** No design decision yet; needs further design or user input.
- **Deferred:** Out of scope for this enhancement; tracked for follow-up.

---

## Q1 — Genuinely open: Component-level vs Module-level `#Claim` resolution semantics

When a Module has both component-level `#claims` (inside a `#Component`) and module-level `#claims` (top-level on `#Module`), what is the resolution order if they reference the same Claim type?

Specifically:

- If a component has `#claims.db` and the module has `#claims.db`, do they merge, override, or conflict?
- Does the platform treat a module-level Claim as a singleton that all components share, or as an additional independent claim?
- If two components each have `#claims.db` of the same type, do they share one fulfillment or get two independent fulfillments?

**Revisit trigger:** Before pipeline implementation begins. The matching algorithm must answer this.

**Lean direction:** Module-level Claims are singletons; component-level Claims are per-component instances. Same Claim type at both levels is allowed (a module may need a shared DB *and* each component may have its own cache); naming distinguishes them.

---

## Q2 — Genuinely open: Specialty Claim type versioning across vendors

Two vendors might independently ship a Claim type with the same `metadata.name` (e.g. both ship `vector-index`) at different `modulePath`s. The `fqn` (`modulePath` + `name` + `version`) disambiguates, but a consumer Module that imports both will face naming collisions in CUE.

- Is there a naming convention recommendation for vendor-published Claims (e.g. always include vendor domain in `name`: `vendor-vector-index`)?
- Or do consumers always alias on import (CUE `import vendora "vendor-a.com/..."`)?
- Should the platform enforce uniqueness at deploy time, or accept multiple `fqn`s with the same `name` from different paths?

**Revisit trigger:** First conflict between two real ecosystem participants.

---

## Q3 — Genuinely open: Self-service catalog API

D12 leaves `#Api` deploy-time semantics open ("platform doesn't care"). However, if the OPM platform implements both a self-service catalog and a deploy-time match cache, the platform-side API surface for those needs definition:

- What CLI does a platform admin use to list registered Apis? (`opm api list`?)
- How does a developer browse the self-service catalog? (Web UI? CLI? OPM-platform-specific?)
- How does the matching pipeline expose its decisions? (`opm claim resolve` showing matched fulfiller?)

These are platform-implementation questions, not primitive-design questions, but they constrain the metadata that `#Api.metadata` should carry.

**Revisit trigger:** When a platform implementation begins. Likely landed in `opm-operator/` or `cli/`.

---

## Q4 — Genuinely open: Validation of `#Claim` request `#spec` against the type definition

A Module's `#claims` reference a Claim type and provide `#spec` values. CUE unification validates the values against the type's schema at authoring time. But when a `#Claim` is serialized and sent to the platform for matching, validation must happen again at deploy time.

- Does the platform re-validate the `#spec` against the embedded `#Claim` definition before matching?
- If a vendor publishes a new version of `#VectorIndexClaim` with a stricter schema, do existing consumer Modules break or stay pinned to the old version they imported?
- Is there a Claim version-compatibility policy (semver-like)?

**Revisit trigger:** First Claim version evolution by a real ecosystem participant.

---

## Q5 — Resolved-but-pending-implementation: `#Api` runtime mechanism

D12 says the platform may use `#Api` for self-service catalog, match cache, or both. Implementation must decide:

- Does deploying a Module with `#apis` write to a platform-level registry (CRD instance? OPM operator state?) so other Modules' `#claims` can resolve at deploy time?
- If yes, is the registry per-environment (each platform has its own) or per-bundle?
- What happens if a Claim is requested but no fulfilling `#Api` is registered yet — error, deferred, fallback?

**Revisit trigger:** During platform-runtime implementation in `opm-operator/`.

---

## Q6 — Deferred: Migration plan for existing Modules

Existing Modules use the current `#Module` shape with `#policies`. The flat shape adds `#lifecycles`, `#workflows`, `#claims`, `#apis` as optional. No existing field is removed.

- Migration path: existing Modules continue to work unchanged (all new fields are optional).
- New fields can be adopted incrementally per Module.
- No tooling required for the migration itself.

**Confirmed safe:** Backwards-compatible because all new fields are optional.

**Revisit trigger:** Only if a future change makes any new field required.

---

## Q7 — Genuinely open: Should `#Resource` and `#Directive` apiVersion become open like `#Claim`?

D10 leaves `apiVersion` open on `#Claim` so vendor specialties can set their own. `#Resource` and `#Directive` today pin `apiVersion: "opmodel.dev/core/v1alpha1"` (see `core/v1alpha1/primitives/resource.cue`, `directive.cue`).

- Should we make `#Resource` and `#Directive` apiVersion open for consistency?
- Would that allow vendors to ship Resources outside the catalog?
- Or is the catalog-fixed nature of Resources (D5) the reason to keep apiVersion pinned?

**Lean direction:** Keep `#Resource` apiVersion pinned (catalog-fixed semantics). `#Directive` is more debatable — directives are operational verbs that vendors might extend, similar to Claims. Worth a separate enhancement.

**Revisit trigger:** First vendor-published Directive request.

---

## Q8 — Genuinely open: Component-scoped `#Api`?

D14 establishes `#Resource` is component-only. `#Api` is module-only. But: could a single component within a Module have its own `#Api`? E.g., one component fulfills `ManagedDatabase`, another fulfills `BackupTarget`, both inside the same operator Module.

Currently the Module's `#apis` map serves this — each `#Api` entry can be associated with whatever component does the work via deployment. But is there value in component-scoped `#apis` for clearer authoring?

**Lean direction:** No. Module-level `#apis` is sufficient; the operator-Module is the unit of capability registration. If a component is independently deployable, it should be its own Module.

**Revisit trigger:** If a real operator design produces awkward `#apis` placement.

---

## Q9 — Deferred: Examples of well-known commodity Claims

This enhancement establishes the pattern. The catalog must populate well-known commodity Claims to make the pattern useful. Initial candidates:

- `#ManagedDatabaseClaim` (data) — relational DBs
- `#MessageBusClaim` (data) — pub/sub queues
- `#ObjectStoreClaim` (data) — S3-compatible buckets
- `#HostnameClaim` (platform) — public DNS names
- `#WorkloadIdentityClaim` (platform) — module-level identity
- `#ImageRegistryClaim` (platform) — image registry endpoints
- `#TLSCertificateClaim` (network) — TLS certs
- `#MeshTenantClaim` (network) — service mesh membership

Each needs its own Claim definition triplet (`#X`, `#XDefaults`, `#XClaim`) in the appropriate `claims/` subpackage.

**Revisit trigger:** During or after initial implementation. Each commodity may warrant its own enhancement for schema design.

---

## Q10 — Genuinely open: Interaction with `#PolicyTransformer` from enhancement 011

Enhancement 011 introduces `#PolicyTransformer` for matching `#Policy` (with rules + directives) against components. `#PolicyTransformer` operates on the verb-flavor commodity surface. This enhancement introduces `#Claim` / `#Api` for the noun-flavor surface.

- Are these two pipelines independent, or do they interact?
- Could a `#Directive` in a Policy reference a `#Claim` (e.g., a backup Directive that targets a `BackupTargetClaim`)?
- Does the rendering pipeline run `#PolicyTransformer`s and `#Claim`/`#Api` matching in sequence, parallel, or interleaved?

**Revisit trigger:** During implementation of either pipeline; likely exposes the interaction.

---

## Q11 — Deferred: Relationship to enhancement 012's noun grammar

Enhancement 012 explores cross-component noun grammar (shared networks, identities, storage pools). This enhancement provides a noun answer at module/component scope (`#Claim` for needs, `#Api` for provided capabilities). But 012's "shared mesh tenant across multiple Modules" use case may still need a higher-level construct.

- Does `#Claim` at module level fully cover 012's noun grammar, or is there still a gap at the bundle / environment level?
- Does 012 need to converge before this enhancement lands, or can they ship independently?

**Lean direction:** Independent. `#Claim` covers per-Module nouns. 012 may still need work for cross-Module shared nouns (a single mesh tenant joined by multiple Modules).

**Revisit trigger:** When 012 reaches design phase.

---

## Q12 — Resolved-but-pending-implementation: Where do `#Api` matches resolve at deploy time?

When a platform deploys two Modules — one with `#claims: db: ...ManagedDatabaseClaim` and one with `#apis: pg: schema: ...ManagedDatabaseClaim` — at what point in the deployment pipeline does the match happen?

Candidates:

- **Pre-deployment (CLI-level):** `opm release plan` resolves matches and surfaces unresolved claims.
- **Admission (operator-level):** OPM operator admission controller verifies matches before applying.
- **Runtime (controller-level):** A claim controller watches Claim CRDs and routes to fulfilling Apis.

**Revisit trigger:** During platform-runtime implementation. Likely answered by `opm-operator/` design.

---

## Q13 — Genuinely open: `#Api.metadata.examples` schema

Current design: `#Api.metadata.examples: _` (freeform). For self-service catalog UI:

- Should `examples` be structured (e.g. `[Name=string]: {description?, spec: claim.#spec}`)?
- Or freeform to let UI implementations choose?

**Lean direction:** Start freeform; structure if a self-service UI implementation needs it.

**Revisit trigger:** First self-service catalog UI implementation.

---

## Summary of Genuinely Open Questions

| ID | Topic | Blocking implementation? |
|----|-------|--------------------------|
| Q1 | Component vs module Claim resolution | Yes |
| Q2 | Specialty Claim versioning across vendors | No (eventual) |
| Q3 | Self-service catalog API | No (platform-impl) |
| Q4 | Claim spec validation at deploy time | Yes (matching) |
| Q7 | `#Resource` / `#Directive` apiVersion openness | No (consistency) |
| Q8 | Component-scoped `#Api` | No |
| Q10 | Interaction with `#PolicyTransformer` (011) | Yes (pipeline) |
| Q13 | `#Api.metadata.examples` schema | No |
