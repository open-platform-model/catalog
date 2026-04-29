# Design Decisions — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

## Summary

Decision log for all architectural and design choices made during this enhancement. Each decision is numbered sequentially and recorded as it is made. Decisions are append-only — do not remove or renumber existing entries. If a decision is reversed, add a new decision that supersedes it.

---

## Decisions

### D1: Single `#Module` type, no kind discrimination

**Decision:** `#Module` remains a single type that simultaneously covers Applications, API descriptions, and Operators. No `#AppModule` / `#APIModule` / `#OperatorModule` split.

**Alternatives considered:**

- Discriminated kinds (`#AppModule`, `#APIModule`, `#OperatorModule`) — clearer reading of intent at a glance, but locks the dual/triple-use at the type level and forces every CLI command and tool to know which kinds it handles.

**Rationale:** Vision goal is extreme flexibility. A Module that is both an Operator and an API Module (an operator that publishes a CRD-backed self-service API) is a legitimate, expected case. Splitting types fragments tooling and forces author choices that the type system should not require.

**Source:** User decision 2026-04-28 in design conversation.

---

### D2: Flat `#Module` field structure

**Decision:** `#Module` has nine flat top-level fields: `metadata`, `#config`, `debugValues`, `#components`, `#policies`, `#lifecycles`, `#workflows`, `#claims`, `#apis`. No grouping (no `#aspects`, `#contract`, `#behavior`, `#ports`, etc.).

**Alternatives considered:**

- One open `#aspects` map discriminated by `kind` — pinned `#Module` at four fields forever, but lost per-field schema enforcement and diluted the grouping.
- Two-bucket `#behavior` + `#ports` (or `#runtime` + `#surface`) — clean inward/outward split, but words felt muddy and added an unneeded layer of nesting.
- Nested grouping by category (governance / contracts / operations) — heavier authoring; new primitive forces a categorization decision.

**Rationale:** With `#Action` removed from top level (D3) and the primitive list bounded at five adornments, the field count is stable. Each field name predicts what is inside. Grouping only earns its keep when the list is unbounded; it is not.

**Source:** User decision 2026-04-28 ("go flat").

---

### D3: Remove `#Action` from `#Module` top level

**Decision:** `#Action` is not a top-level slot on `#Module`. `#Action` is a primitive consumed by `#Lifecycle` and `#Workflow` constructs.

**Alternatives considered:**

- `#actions: [Id=string]: action.#Action` at module level — symmetric with other primitives, but redundant since Lifecycle and Workflow already compose Actions internally.

**Rationale:** `#Action` is a building block, not a module-level concern. Module authors do not write Actions in isolation; they write Lifecycles and Workflows, which compose Actions.

**Source:** User decision 2026-04-28.

---

### D4: Replace `#Offer` with `#Api`

**Decision:** Supply-side capability registration is named `#Api`. Archived enhancement 007's `#Offer` primitive is not adopted.

**Alternatives considered:**

- Keep `#Offer` (007's name) — symmetric with `#Claim` in language ("offer" mirrors "claim"), but less aligned with common platform vocabulary.

**Rationale:** `#Api` matches widely understood platform terminology ("API surface", "self-service API"). When a `#Module` deploys to an OPM platform, an `#Api` registers the capability — this becomes a CRD in a Kubernetes context and a self-service catalog entry in the OPM platform context.

**Source:** User decision 2026-04-28.

---

### D5: Keep both `#Resource` and `#Claim`

**Decision:** `#Resource` and `#Claim` are distinct primitives with sharpened litmus questions. Neither is absorbed into the other.

**Alternatives considered:**

- Absorb `#Claim` into `#Resource` and allow Resource at module level — fewer primitives, but loses the runtime extensibility signal and the demand/supply asymmetry that makes `#Api` meaningful.

**Rationale:** Resources are catalog-fixed and transformer-rendered. Claims are ecosystem-extended and provider-fulfilled. The two answer different questions for different ecosystem layers. Absorbing them blurs the specialty-services innovation surface.

**Source:** User decision 2026-04-28.

---

### D6: No separate `#ClaimType` primitive

**Decision:** `#Claim` serves as both the type definition (in catalog or vendor packages) and the request (in `#claims`) via CUE unification. There is no `#ClaimType` primitive.

**Alternatives considered:**

- `#ClaimType` (defines schema) + `#Claim` (request) as separate primitives — gRPC-like split with sharper roles, but added a primitive without proportional benefit.
- Schema embedded in `#Api` (whoever publishes first owns the schema) — fragile.

**Rationale:** CUE's package system already provides type identity. Catalog-published `#Claim` definitions (e.g. `#ManagedDatabaseClaim`) are simultaneously the type and the request shape — instances unify with the definition.

**Source:** User decision 2026-04-28.

---

### D7: `#Claim` carries `apiVersion` + path metadata for traceability

**Decision:** `#Claim` includes `apiVersion` and `metadata.{modulePath, name, version, fqn}` for identity. There is no string `type` field. Matching is structural at the CUE level and metadata-driven at deploy time.

**Alternatives considered:**

- `type: string` field for runtime lookup — simpler, but loses CUE-level structural matching and creates a naming-collision risk.
- Identity solely via CUE references (no explicit metadata) — works at authoring time but breaks when claims serialize across module boundaries.

**Rationale:** Identity must travel beyond CUE references when a Module is serialized for deploy-time matching. The `apiVersion` + `fqn` pair is the carrier — same role as Kubernetes' `apiVersion` + `kind`, or Go's package path.

**Source:** User decision 2026-04-28.

---

### D8: `#Api` is 1:1 with `#Claim`

**Decision:** Each `#Api` embeds exactly one `#Claim` as its `schema` field. A Module that fulfills multiple capabilities ships multiple `#api` entries in the `#apis` map.

**Alternatives considered:**

- 1:N (`#Api` embeds a list of `#Claim`s via a `schemas` field) — more compact for multi-fulfillers, but breaks parallel structure with `#components`, `#claims`, and other map-typed slots.

**Rationale:** Map-as-set ergonomics in CUE favor 1:1. A Postgres operator that fulfills both `ManagedDatabase` and `BackupTarget` ships two clear, parallel `#api` entries — easier to read, easier to evolve, easier to remove one without touching the other.

**Source:** User decision 2026-04-28 (Q1: 1:1).

---

### D9: Triplet pattern for concrete Claim definitions

**Decision:** Concrete `#Claim` definitions follow the existing catalog triplet pattern: `#X` (schema) + `#XDefaults` (defaults) + `#XClaim` (`#Claim` wrapper).

**Alternatives considered:**

- Single-definition collapse — `#ManagedDatabase: claim.#Claim & {...}` — fewer definitions but inconsistent with how `#Container` / `#ContainerDefaults` / `#ContainerResource` are organized for Resources.

**Rationale:** Catalog consistency. Authors moving between Resources and Claims see the same pattern. Defaults stay separable so consumers can opt in.

**Source:** User decision 2026-04-28 (Q2: Yes).

---

### D10: `apiVersion` is open on the `#Claim` base; concrete Claims set their own

**Decision:** The `#Claim` primitive base type leaves `apiVersion` as `string!` (required, open). Concrete Claim definitions (e.g. `#ManagedDatabaseClaim`, `#VectorIndexClaim`) set their own `apiVersion`. The base does not pin one.

**Alternatives considered:**

- Pin `apiVersion: "opmodel.dev/core/v1alpha1"` on `#Claim` base — consistent with `#Resource` and `#Directive`, but forces vendor specialty Claims to live under OPM's apiVersion or break the constraint.

**Rationale:** `apiVersion` belongs to the catalog or vendor that published the Claim, not the OPM core primitive. A vendor's `#VectorIndexClaim` should carry `apiVersion: "vendor.com/vectordb/v1alpha1"` — open base allows this naturally. (This differs from `#Resource` and `#Directive` which today pin `apiVersion` to OPM core; revisit those for consistency in a follow-up.)

**Source:** User decision 2026-04-28 (Q3: Yes, mirror; allow apiVersion open).

---

### D11: CRDs deploy via `#CRDsResource` in `#components`, not via `#Api`

**Decision:** `#Api` carries no CRD installation logic. Operators continue to ship CRDs as `#CRDsResource` inside their `#components`.

**Alternatives considered:**

- Embed CRD schema in `#Api.schema` so `#Api` declaration triggers CRD installation — couples platform-level capability registration to k8s-specific CRD lifecycle.

**Rationale:** Existing `#CRDsResource` pattern works. `#Api` is a platform-level concept (capability + self-service catalog); CRDs are a Kubernetes-provider concern. Keeping them separate preserves layer boundaries.

**Source:** User decision 2026-04-28.

---

### D12: `#Api` deploy-time semantics are platform's choice

**Decision:** `#Api` is purely declarative. The platform may use it to populate a self-service catalog, a deploy-time match cache, both, or any equivalent mechanism. The primitive does not pin the runtime behavior.

**Alternatives considered:**

- Catalog-only ("`#Api` is documentation") — loses the deploy-time matching story.
- Match-cache-only ("`#Api` is wiring") — loses the self-service catalog story.
- Strict pinned spec — over-constrains platform implementations.

**Rationale:** `#Api` declares intent; the platform decides how to honor it. Different OPM platforms (Kubernetes, OPM-as-a-service, future bare-metal) may implement registration differently. The primitive is the contract; the runtime is open.

**Source:** User decision 2026-04-28 (Q5: Option 3 — platform doesn't care).

---

### D13: Both component-level and module-level `#Claim` placement

**Decision:** `#Claim` may be placed at component level (data-plane needs — DB, queue, cache, secret) or at module level (platform-relationship needs — DNS, tenant admission, identity, observability backend, mesh membership). Same primitive, two scopes; placement determines semantics.

**Alternatives considered:**

- Component-only — forces module-as-unit needs onto an arbitrary "primary" component, coupling the claim to a component implementation choice.
- Module-only — forces every per-component data-plane need up to module level, decoupling claim from the component that actually uses it.
- Two distinct primitives (`#Claim` for component, `#ModuleClaim` for module) — adds vocabulary for what is structurally the same primitive.

**Rationale:** Two flavors of need genuinely exist: per-component data-plane and per-module platform-relationship. Both are "I need X from the ecosystem." Placement carries the scope information cleanly.

**Source:** User decision 2026-04-28 (Q4: Yes, both).

---

### D14: `#Resource` stays component-level only

**Decision:** `#Resource` is not allowed at module level. Shared resources should be modeled as their own `#Component`.

**Alternatives considered:**

- Allow Resource at module level for shared infra (e.g. shared ConfigMap) — convenient but blurs the component composition model.

**Rationale:** Components are the unit of composition. Shared infra is its own component, with other components depending on it. Allowing module-level Resources collapses that boundary.

**Source:** User decision 2026-04-28.

---

### D15: Sharpened litmus for `#Resource` and new entries for `#Claim` / `#Api`

**Decision:** `docs/core/definition-types.md` litmus is updated:

- `#Resource`: "What well-known thing must be rendered?" (sharpened from "What must exist?")
- `#Claim`: "What ecosystem-supplied thing must be fulfilled?" (new)
- `#Api`: "What capability does this Module register?" (new)
- `#Module`: "What is the application, API, or operator?" (sharpened from "What is the application?")

**Alternatives considered:**

- Leave Resource's litmus unchanged and add Claim with a similar phrasing — perpetuates the overlap.

**Rationale:** Without distinct litmus questions, authors cannot pick between `#Resource` and `#Claim` from the doc alone. The sharpened pair maps to the **catalog-fixed vs. ecosystem-extended** axis (D5).

**Source:** Design discussion 2026-04-28.

---

### D16: `#Api` primitive has its own apiVersion pinned to OPM core

**Decision:** `#Api`'s base type pins `apiVersion: "opmodel.dev/core/v1alpha1"`. Unlike `#Claim` (D10), `#Api` is not extended by vendors as a base type — vendors author `#Claim` definitions and reference them via `#Api.schema`. The `#Api` primitive itself remains an OPM core type.

**Alternatives considered:**

- Open `apiVersion` on `#Api` parallel to `#Claim` — but vendors do not redefine `#Api` as a primitive; they only embed Claims into it.

**Rationale:** `#Api` is the wrapper. The variation comes from the embedded `schema`, not from `#Api` itself.

**Source:** Design discussion 2026-04-28.
