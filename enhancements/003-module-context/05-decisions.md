# Design Decisions — Module Context (`#ctx`)

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for all design choices made during the module context (`#ctx`) design.

---

## Decisions

### D1: Field Name — `#ctx`

**Decision:** The context field on `#Module` is named `#ctx`.

**Alternatives considered:**

- `#context` — more explicit but more verbose; rejected because the field appears in every module definition and the extra characters add noise without adding clarity

**Rationale:** Concise naming is consistent with the project's tendency toward short definition names (e.g., `#config`, `#module`). The `#` prefix already signals that this is a definition-level field, and `ctx` is a universally understood abbreviation in the systems context.

**Source:** Design session 2026-03-25

---

### D2: Field Kind — CUE Definition (`#`-prefixed)

**Decision:** `#ctx` is a CUE definition field (`#`-prefixed), not a regular value field.

**Alternatives considered:**

- Regular value field — rejected: regular fields are included in `cue export` output and would contaminate rendered Kubernetes YAML with internal context data

**Rationale:** CUE definitions are excluded from export output by default. Since `#ctx` is computation-internal and must never appear in rendered manifests, the definition kind is the correct choice.

**Source:** Design session 2026-03-25; CUE export semantics

---

### D3: Two-Layer Structure — `runtime` + `platform`

**Decision:** `#ctx` is structured as two named layers: `runtime` (OPM-owned, schema-validated) and `platform` (open, platform-team-owned).

**Alternatives considered:**

- Single flat struct — rejected: no clear ownership boundary between OPM-defined and platform-defined fields; versioning and evolution become difficult as both OPM and platform teams add fields

**Rationale:** A clear ownership boundary allows OPM to evolve `runtime` with a stable schema contract while giving platform teams an unambiguous, unconstrained extension point. Neither layer pollutes the other.

**Source:** Design session 2026-03-25

---

### D4: `platform` Extension Shape — Flat Open Struct

**Decision:** The `platform` layer is a flat open struct (`{ ... }`). Platform teams add fields directly without any enforced key convention.

**Alternatives considered:**

- Namespaced map `[#ExtensionName]: _` — deferred; premature to impose structure before actual platform extension patterns are known in practice

**Rationale:** The flat struct is the simplest possible extension point. Conventions can emerge organically and be formalised later if key collision or auditability becomes a problem. See [N4 in 06-notes.md](06-notes.md) for the follow-up trigger.

**Source:** Design session 2026-03-25

---

### D5: Context Scope — Always the Full Bag

**Decision:** All `runtime` fields are always present when `#ctx` is populated. There is no selective or opt-in context injection.

**Alternatives considered:**

- Selective inclusion — rejected: requires modules to declare what context they consume, complicates the schema contract, and makes it harder to reason about what is available at any given point

**Rationale:** A predictable, always-complete context means module authors write against a stable contract without needing to guard for missing fields (except for fields that are explicitly optional, such as `route?`).

**Source:** Design session 2026-03-25

---

### D6: Relationship to `#config` — Separate, Never Merged

**Decision:** `#ctx` is never merged with `#config`. They are distinct fields with distinct owners and distinct schemas.

**Alternatives considered:**

- Unified single input — rejected: violates the OpenAPI constraint on `#config` (which must be a valid OpenAPI schema); would blur authoring responsibility between application operators and platform operators

**Rationale:** `#config` is the operator-supplied values contract — it describes what an application needs. `#ctx` is the runtime-supplied environment contract — it describes where the application is running. Mixing them breaks both the semantic distinction and the technical constraint that `#config` must be OpenAPI-compatible.

**Source:** Design session 2026-03-25

---

### D7: Computation Location — CUE Catalog Side via `#ContextBuilder`

**Decision:** `#ctx` is computed entirely in CUE, via a `#ContextBuilder` helper defined in the catalog and used by `#ModuleRelease`.

**Alternatives considered:**

- Go-side computation with `FillPath` injection (as `#TransformerContext` is done today) — possible but would move computation logic out of the schema and into Go, reducing CUE-native discoverability and making the context harder to test in isolation

**Rationale:** Computing in CUE is consistent with how `#AutoSecrets` and other derived values are handled. The `#ContextBuilder` helper is independently testable as a CUE value, does not require Go changes for the core computation, and keeps the schema self-documenting.

**Source:** Design session 2026-03-25

---

### D8: `#environment` Input — New Optional Field on `#ModuleRelease`

**Decision:** Cluster and route domain values are supplied to `#ModuleRelease` via a new optional `#environment` field, separate from both `values` and `metadata`.

**Alternatives considered:**

- Part of `values` — rejected: breaks the contract that `values` satisfies `#config`; operators should not mix cluster infrastructure details into application configuration

**Rationale:** `#environment` is a distinct concern — it describes the cluster the release runs in, not the application's configuration. Keeping it separate preserves the clean separation between application config (`values`), release identity (`metadata`), and deployment environment (`#environment`). CUE-level defaults can be provided without Go involvement.

**Source:** Design session 2026-03-25

---

### D9: Default `clusterDomain` — `"cluster.local"`

**Decision:** When `#environment.clusterDomain` is not supplied, it defaults to `"cluster.local"`.

**Alternatives considered:**

- No default, require explicit injection — rejected: would break all existing modules until every release file is updated; a backwards-incompatible requirement with no practical benefit

**Rationale:** `"cluster.local"` is the correct default for the vast majority of Kubernetes clusters. The value is overridable via `#environment` without any module change when a non-standard domain is needed.

**Source:** Design session 2026-03-25

---

### D10: `route` Field Optionality — `route?`

**Decision:** The `route` field inside `#ctx.runtime` is optional (`route?`). When no route domain is configured, the field is absent rather than set to an empty string or a sentinel value.

**Alternatives considered:**

- Default empty string — rejected: silently produces malformed URLs when modules interpolate the field without checking for its presence

**Rationale:** Not all clusters have an ingress or route domain. Making the field absent when not configured forces module authors to write explicit guards (`if #ctx.runtime.route != _|_`), which is safer than relying on a magic value that could produce subtly broken output.

**Source:** Design session 2026-03-25

---

### D11: `#ComponentNames` Cascading Derivation from `resourceName`

**Decision:** All DNS name variants inside `#ComponentNames` are derived from a single `resourceName` field via interpolation defaults. Overriding `resourceName` automatically propagates to all variants.

**Alternatives considered:**

- Independent computation for each DNS variant — rejected: creates four separate places to update when the naming strategy changes; makes future `nameOverride` support more complex

**Rationale:** A single source of truth for the base name (`resourceName`) means the entire cascade of DNS variants stays consistent automatically. Future override support (see [N1 in 06-notes.md](06-notes.md)) only needs to target `resourceName` rather than each variant independently.

**Source:** Design session 2026-03-25

---

### D12: Content Hash Location — Centralised in `#ctx.runtime.components`

**Decision:** Content hashes for secrets and configMaps are stored at `#ctx.runtime.components[name].hashes`, not computed in individual transformers.

**Alternatives considered:**

- Keep hashes in transformers only — rejected: perpetuates the scattered, convention-dependent hash computation identified in the `02-resource-name-override` design; provides no module-level access to hash values

**Rationale:** Centralising hash computation at `#ctx` provides a single lookup point for both module components and transformers, eliminates duplication, and aligns with the principle of one computation site per derived value.

**Source:** Design session 2026-03-25; `catalog/design/02-resource-name-override/`

---

### D13: Content Hash Injection Timing — Strategy B (Go-Side)

**Decision:** Content hashes are injected into `#ctx` by the Go pipeline after component spec resolution, before the transformer loop. This is Strategy B.

**Alternatives considered:**

- Strategy A: two-pass CUE evaluation — the first pass resolves specs, the second injects hashes back into `#ctx`; deferred because it adds CUE evaluation complexity without a current use case that requires it

**Rationale:** Strategy B avoids a circular CUE dependency (hashes require evaluated specs; specs require `#ctx`). It follows the existing `injectContext()` pattern and carries lower implementation risk. If a use case emerges where a component spec must reference its own hash before rendering, Strategy A can be revisited. See [N5 in 06-notes.md](06-notes.md).

**Source:** Design session 2026-03-25

---

### D14: `#TransformerContext` Relationship — Deferred

**Decision:** The relationship between `#ctx` and `#TransformerContext` is not resolved in this design. `#TransformerContext` is kept as-is.

**Alternatives considered:**

- Immediate replacement or extension of `#TransformerContext` — deferred; doing both simultaneously increases scope and risk

**Rationale:** Unifying `#ctx` and `#TransformerContext` is a separate design concern. `#TransformerContext` continues to work unchanged. A follow-up design must decide whether to replace, extend, or maintain the two as separate concerns. See [N2 in 06-notes.md](06-notes.md).

**Source:** Design session 2026-03-25

---

### D15: Bundle-Level Context — Deferred

**Decision:** This design establishes module-level context only. Bundle-level context (cross-module references) is out of scope.

**Alternatives considered:**

- Include bundle context in this design — rejected: adds significant complexity before module-level context is proven; requires a bundle-level scope that does not yet exist in the schema

**Rationale:** Cross-module context references require a `#BundleRelease`-level scope that has not been designed. Attempting to build that scope here would expand the design beyond what is needed for the initial feature. See [N3 in 06-notes.md](06-notes.md).

**Source:** Design session 2026-03-25

---

### D16: `#ContextBuilder` Location — `catalog/core/v1alpha1/helpers/`

**Decision:** The `#ContextBuilder` helper is placed at `catalog/core/v1alpha1/helpers/context_builder.cue`.

**Alternatives considered:**

- Inline in `module_release.cue` — functional, but makes the release definition harder to read; the helpers pattern is already established by `#OpmSecretsComponent` and should be followed consistently

**Rationale:** Placing `#ContextBuilder` in the helpers package keeps it importable from `#ModuleRelease` without circular imports, independently testable as a CUE value, and consistent with the existing pattern for catalog-side computation helpers.

**Source:** Design session 2026-03-25; `#OpmSecretsComponent` precedent in `catalog/core/v1alpha1/helpers/`
