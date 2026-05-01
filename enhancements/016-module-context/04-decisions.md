# Design Decisions — `#ctx` Module Runtime Context

## Summary

Decision log for `#ctx`. Append-only — do not remove or renumber existing entries. If a decision is reversed, add a new decision that supersedes it.

Most decisions here carry forward verbatim from the archived [008-platform-construct](../archive/008-platform-construct/07-decisions.md), where the ctx work originated. Where a decision was made specifically by 008, the original D-number is noted in parentheses; the rationale and source are preserved. New decisions specific to this enhancement (the 008 split) are recorded after the carried-forward set.

---

## Carried-Forward Decisions

### D1: Field name — `#ctx`

**Decision:** The context field on `#Module` is named `#ctx`.

**Alternatives considered:**

- `#context` — more explicit but more verbose; rejected because the field appears in every module definition and the extra characters add noise without adding clarity.

**Rationale:** Concise naming is consistent with the project's tendency toward short definition names (`#config`, `#module`). The `#` prefix already signals definition-level; `ctx` is universally understood in the systems context.

**Source:** Archived 008 D1 (Design session 2026-03-25).

---

### D2: Field kind — CUE definition (`#`-prefixed)

**Decision:** `#ctx` is a CUE definition field, not a regular value field.

**Alternatives considered:**

- Regular value field — rejected: regular fields are included in `cue export` output and would contaminate rendered Kubernetes YAML with internal context data.

**Rationale:** CUE definitions are excluded from export by default. `#ctx` is computation-internal and must never appear in rendered manifests.

**Source:** Archived 008 D2.

---

### D3: Two-layer structure — `runtime` + `platform`

**Decision:** `#ctx` is structured as two named layers: `runtime` (OPM-owned, schema-validated) and `platform` (open struct, platform-team-owned).

**Alternatives considered:**

- Single flat struct — rejected: no clear ownership boundary between OPM-defined and platform-defined fields; versioning and evolution become difficult as both OPM and platform teams add fields.

**Rationale:** Clear ownership boundary lets OPM evolve `runtime` with a stable schema contract while giving platform teams an unambiguous, unconstrained extension point. Neither layer pollutes the other.

**Source:** Archived 008 D3.

---

### D4: `platform` extension shape — flat open struct

**Decision:** The `platform` layer is a flat open struct (`{ ... }`). Platform teams add fields directly without an enforced key convention.

**Alternatives considered:**

- Namespaced map `[#ExtensionName]: _` — deferred; premature to impose structure before actual platform extension patterns are known in practice.

**Rationale:** Simplest possible extension point. Conventions can emerge organically and be formalised later if key collision or auditability becomes a problem.

**Source:** Archived 008 D4.

---

### D5: Context scope — always the full bag

**Decision:** All `runtime` fields are always present when `#ctx` is populated. No selective or opt-in injection.

**Alternatives considered:**

- Selective inclusion — rejected: would force modules to declare what context they consume, complicate the schema contract, and make it harder to reason about what is available at any given point.

**Rationale:** Predictable, always-complete context lets module authors write against a stable contract without guarding for missing fields (except for explicitly optional fields like `route?`).

**Source:** Archived 008 D5.

---

### D6: Relationship to `#config` — separate, never merged

**Decision:** `#ctx` is never merged with `#config`. They are distinct fields with distinct owners and distinct schemas.

**Alternatives considered:**

- Unified single input — rejected: violates the OpenAPI constraint on `#config` and blurs authoring responsibility between operators and platform teams.

**Rationale:** `#config` is the operator-supplied values contract — what an application needs. `#ctx` is the runtime-supplied environment contract — where the application is running. Mixing them breaks both the semantic distinction and the technical OpenAPI constraint on `#config`.

**Source:** Archived 008 D6.

---

### D7: Computation location — CUE catalog side via `#ContextBuilder`

**Decision:** `#ctx` is computed entirely in CUE, via a `#ContextBuilder` helper defined in the catalog and used by `#ModuleRelease`.

**Alternatives considered:**

- Go-side computation with `FillPath` injection — possible but moves computation logic out of the schema and into Go, reducing CUE-native discoverability and making the context harder to test in isolation.

**Rationale:** Computing in CUE is consistent with `#AutoSecrets` and other derived values. `#ContextBuilder` is independently testable as a CUE value, requires no Go changes for the core computation, and keeps the schema self-documenting.

**Source:** Archived 008 D7.

---

### D8: Default `clusterDomain` — `"cluster.local"`

**Decision:** When `clusterDomain` is not supplied, it defaults to `"cluster.local"`. The default lives at `#PlatformContext.runtime.cluster.domain`.

**Alternatives considered:**

- No default, require explicit injection — rejected: would break all existing modules until every release file is updated; backwards-incompatible with no practical benefit.

**Rationale:** `"cluster.local"` is correct for the vast majority of Kubernetes clusters. The value is overridable at the environment or platform level without any module change when a non-standard domain is needed.

**Source:** Archived 008 D8.

---

### D9: `route` field optionality — `route?`

**Decision:** The `route` field inside `runtime` is optional (`route?`). When no route domain is configured, the field is absent rather than set to an empty string or sentinel.

**Alternatives considered:**

- Default empty string — rejected: silently produces malformed URLs when modules interpolate the field without checking for presence.

**Rationale:** Not all clusters have an ingress or route domain. Making the field absent forces explicit guards (`if #ctx.runtime.route != _|_`), which is safer than relying on a magic value that produces subtly broken output.

**Source:** Archived 008 D9.

---

### D10: `#ComponentNames` cascading derivation from `resourceName`

**Decision:** All DNS name variants inside `#ComponentNames` are derived from a single `resourceName` field via interpolation defaults. Overriding `resourceName` automatically propagates to all variants.

**Alternatives considered:**

- Independent computation for each DNS variant — rejected: creates four separate update sites when the naming strategy changes; makes future overrides more complex.

**Rationale:** Single source of truth for the base name. The cascade keeps DNS variants consistent automatically. The `metadata.resourceName` override (D13) targets `resourceName` only — all variants propagate automatically.

**Source:** Archived 008 D10.

---

### D11: Content hash location — centralised in `#ctx.runtime.components`

**Decision:** Content hashes for ConfigMaps and Secrets are stored at `#ctx.runtime.components[name].hashes`, not computed inside individual transformers.

**Alternatives considered:**

- Keep hashes in transformers only — rejected: perpetuates scattered, convention-dependent hash computation; provides no module-level access to hash values.

**Rationale:** Centralising hash computation provides a single lookup point for both module components and transformers, eliminates duplication, and aligns with one-computation-site-per-derived-value.

**Source:** Archived 008 D11.

---

### D12: Content hash injection timing — Strategy B (Go-side)

**Decision:** Content hashes are injected into `#ctx` by the Go pipeline after component spec resolution, before the transformer loop. The CUE side reserves the schema slot (`#ComponentNames.hashes?`) but does not populate it.

**Alternatives considered:**

- Strategy A: two-pass CUE evaluation where the first pass resolves specs and the second injects hashes back into `#ctx`. Deferred because it adds CUE evaluation complexity without a current use case that requires self-referential hash use inside specs.

**Rationale:** Strategy B avoids a circular CUE dependency (hashes require evaluated specs; specs require `#ctx`). It follows existing `injectContext()` patterns and carries lower implementation risk. Strategy A can be revisited if a use case emerges where a component spec must reference its own hash before rendering.

**Source:** Archived 008 D12.

---

### D13: Resource name override — `metadata.resourceName` on `#Component`

**Decision:** Components can override their Kubernetes resource base name by setting an optional `resourceName` field on `#Component.metadata`. `#ContextBuilder` reads this field and passes it into `#ComponentNames.resourceName`, replacing the default `"{release}-{component}"`. All DNS variants cascade automatically.

**Alternatives considered:**

- Separate `#ComponentContext` struct on `#Component.#ctx` — rejected: creates a CUE cycle risk because `#ctx` flows down from `#ModuleRelease` to `#Module` to components, but the override input flows up.
- Override set directly on `#ctx.runtime.components[key].resourceName` from inside the module — rejected: self-referential.
- Separate `nameOverride` design with its own helper struct — rejected: adds unnecessary complexity. The `#ctx` design already provides centralized naming via `#ComponentNames`.

**Rationale:** Placing the override on component metadata keeps it as a clean input that `#ContextBuilder` reads before computing context. No cycle risk — metadata is set at module-definition time; context is computed at release time. Subsumes the archived [002-resource-name-override](../archive/002-resource-name-override/) design entirely.

**Source:** Archived 008 D13 (Design session 2026-04-11).

---

### D14: `#ContextBuilder` location — `catalog/core/v1alpha2/`

**Decision:** `#ContextBuilder` lives at `catalog/core/v1alpha2/context_builder.cue` (flat package, no `helpers/` subdirectory).

**Alternatives considered:**

- Inline in `module_release.cue` — functional, but harder to read; the helpers pattern is already established by `#OpmSecretsComponent` and should be followed consistently.

**Rationale:** Importable from `#ModuleRelease` without circular imports, independently testable, consistent with the v1alpha2 flat-package layout.

**Source:** Archived 008 D14.

---

### D15: `#TransformerContext` relationship — deferred

**Decision:** The relationship between `#ctx` and `#TransformerContext` is not resolved here. `#TransformerContext` is kept as-is.

**Alternatives considered:**

- Immediate replacement or extension of `#TransformerContext` — deferred to avoid scope creep.

**Rationale:** Unifying `#ctx` and `#TransformerContext` is a separate design concern. `#TransformerContext` continues to work unchanged. A follow-up will decide whether to replace, extend, or maintain the two as separate concerns.

**Source:** Archived 008 D15.

---

### D19: Platform-level context uses `#ctx` shape

**Decision:** Platform-level context is typed `#PlatformContext`, sharing the same two-layer (`runtime` + `platform`) shape as `#ModuleContext`. Replaces an earlier RFC-0001 `#PlatformContext` with a different shape.

**Alternatives considered:**

- Keep RFC-0001 `#PlatformContext` as a separate struct — rejected: creates a separate vocabulary for the same concept; platform context and module context should share a shape so CUE unification merges them naturally.
- Flat fields on Platform (`defaultDomain`, `defaultStorageClass`) — rejected: no clear merge path into `#ModuleContext`.

**Rationale:** Same shape lets platform-level defaults merge into the final `#ModuleContext` via CUE unification with no field-by-field mapping. Platform teams use `#ctx.platform` for extensions, same as in modules.

**Source:** Archived 008 D19.

---

### D20: Bundle-level context — deferred

**Decision:** This enhancement establishes module-level context only. Bundle-level context (cross-module references) is out of scope.

**Alternatives considered:**

- Include bundle context here — rejected: adds significant complexity before module-level context is proven; requires a bundle-level scope that does not yet exist in the schema.

**Rationale:** Cross-module context references require a `#BundleRelease`-level scope that has not been designed. Attempting to build that scope here would expand the design beyond what is needed for the initial feature.

**Source:** Archived 008 D20.

---

### D21: `#Environment` is a new construct

**Decision:** `#Environment` is a catalog construct that targets a `#Platform` and contributes environment-level `#ctx` overrides. `#ModuleRelease` targets an environment, not a platform directly.

**Alternatives considered:**

- `#ModuleRelease` targets `#Platform` directly with inline `#environment` overrides — rejected: conflates platform capabilities with environment specifics; forces release authors to reference both.
- Environment as a field on Platform — rejected: one platform often hosts multiple environments; nesting environments inside platforms couples their lifecycles.

**Rationale:** `#Platform` = "what can this cluster do?"; `#Environment` = "how is this slice of the cluster used?". Different concerns, different constructs. Release authors target an environment and inherit both the platform's capabilities and the environment's context.

**Source:** Archived 008 D21.

---

### D22: `#Environment` does not override `#config`

**Decision:** `#Environment` contributes only to `#ctx`. It does not set or override `#config`.

**Alternatives considered:**

- Allow environment-level value defaults — rejected: blurs the separation between deployment environment and application configuration.

**Rationale:** If environments could set values, the source of a config field becomes ambiguous (release? environment? module default?). Keeping environments limited to `#ctx` preserves the clean ownership boundary established by D6.

**Source:** Archived 008 D22.

---

### D23: `#ModuleRelease` targets environment via `#env`

**Decision:** `#ModuleRelease` has a `#env` definition field referencing the target `#Environment`. The release imports the environment package directly.

**Alternatives considered:**

- `#Config.environments` map with CLI flag lookup — rejected: unnecessary indirection.
- Regular field `environment:` — rejected: must be a definition (`#env`) to avoid appearing in exported output.

**Rationale:** Direct import is the simplest path. The environment carries the platform reference and Layer 2 context; the release gets everything it needs from a single import.

**Source:** Archived 008 D23.

---

### D24: Context hierarchy — Platform → Environment → Release

**Decision:** `#ctx.runtime` fields are populated through a layered override hierarchy: `#Platform.#ctx` → `#Environment.#ctx` → `#ModuleRelease` identity. Each layer can override the previous.

**Alternatives considered:**

- Flat merge with no precedence — rejected: ambiguous when platform and environment set the same field.
- Release can override all context fields — accepted for `namespace` (`metadata.namespace` overrides env default); deferred for other fields to avoid release authors accidentally overriding platform facts.

**Rationale:** Hierarchy matches real-world ownership: platform teams own cluster facts, environment operators own per-env config, release authors own per-module identity.

**Source:** Archived 008 D24.

---

## New Decisions (016-specific)

### D26: Split 008 into 014 (Platform), 015 (Module), 016 (`#ctx`)

**Decision:** The combined design from archived 008 is split across three enhancements. 014 owns `#Platform` composition (`#registry`, computed views over registered Modules). 015 owns the `#Module` shape (slots, `#defines`, `#claims`). 016 (this enhancement) owns the `#ctx` schema, `#Environment` construct, `#ContextBuilder`, and `#Component.metadata.resourceName` override.

**Alternatives considered:**

- Keep 008 as a single landed enhancement — rejected: 008 was archived after the user reshaped the Platform model (registry of Modules, not list of Providers) and the Module model (flat shape with `#defines`). Reusing 008's number for the new shape would conflict with the historical record.
- Bundle ctx into 014 or 015 — rejected: ctx is referenced from both. A standalone enhancement gives both a single source of truth without forcing one to import the other for context schemas.

**Rationale:** Each of the three concerns (platform composition, module shape, runtime context) has independent reviewers, independent landing windows, and independent change risk. Splitting also matches the catalog's small-batch principle (Constitution IX) — three small enhancements are easier to review than one large bundled one.

**Source:** User decision 2026-04-30 ("write a new enhancement based on the context (#ctx) work and decisions from the archived 008-platform-construct enhancement. This is number 016. It should only focus on the #ctx part").

---

### D27: `#Environment` is included in 016 even though its primary role is `#ctx` Layer 2

**Decision:** `#Environment` lives in 016 alongside the `#ctx` schemas. It carries metadata, the `#platform` reference, and `#ctx: #EnvironmentContext`. Future enhancements may extend `#Environment` for non-context concerns (deploy gates, environment-scoped policies, etc.).

**Alternatives considered:**

- Put `#Environment` in 014. Rejected: 014's scope is platform composition; including a deployment-target binding bloats it.
- Put `#Environment` in a separate enhancement. Rejected: `#Environment` and `#ContextBuilder` are tightly coupled — splitting them across enhancements means one cannot land before the other.

**Rationale:** `#Environment` exists structurally as the Layer 2 context node and as the binding `#ModuleRelease.#env` points at. Both responsibilities flow from the context hierarchy. Including it here keeps the layered context system as a self-contained unit. If `#Environment` grows non-context concerns, those can be added through a follow-up enhancement that imports 016.

**Source:** Design discussion 2026-04-30 (016 scope).

---

### D28: `#ctx.platform` extensions are unconstrained even after operational commodities land

**Decision:** Even now that operational commodities (backup, TLS, routing — see [015/08-examples.md](../015-module-defines/08-examples.md) Example 7) populate well-known sub-keys (`backup.backends`, `tls.issuers`, `routing.gateways`), the `#ctx.platform` struct remains an unconstrained open struct. The catalog does not pin these sub-keys as required schema.

**Alternatives considered:**

- Define a `#StandardPlatformExtensions` schema with `backup`, `tls`, `routing` as known sub-keys, and have platforms unify against it. Rejected for v1: requires every platform to validate against the union of every commodity's expected shape; coupling commodities to the core context schema forces sync between unrelated package versions.

**Rationale:** The naming convention (`backup.backends.<name>: {...}`) emerges from the commodity packages themselves (`opmodel.dev/opm/v1alpha2/operations/backup`). Each commodity transformer declares which sub-key it reads via its `readsContext` field; mismatches surface as render-time errors, not CUE-evaluation errors. Convention beats schema constraint here because the open-struct approach lets ecosystem participants ship new commodities without requiring core-catalog PRs. (This matches D4's reasoning at the platform-extension level.)

**Source:** Design discussion 2026-04-30 (after 015 Example 7 lifted the operational-commodity pattern).

---

### D29: Kubernetes vocabulary is canonical for `#ctx.runtime`; non-k8s runtimes derive

**Decision:** `#ctx.runtime` uses Kubernetes vocabulary as the canonical substrate. `cluster.domain`, `release.namespace`, the `dns.{local,namespaced,svc,fqdn}` quartet, and the `hashes.{configMaps,secrets}` slot are all k8s-shaped and treated as the universal contract every runtime presents. Non-Kubernetes runtimes (compose, nomad, future targets) interpret each field name by mapping to local concepts — `namespace` → compose project, `dns.svc` → network alias, `cluster.domain` → empty or `"local"` (informational), and so on. The mapping table lives in `02-design.md` ("Non-Kubernetes Runtime Semantics").

**Alternatives considered:**

- **Generic / abstract field names** (`runtime.searchDomain` instead of `cluster.domain`, `runtime.scope` instead of `namespace`). Rejected: produces lowest-common-denominator field shapes that hide their k8s heritage without earning real portability — compose has no namespaces; the rename does not fix the conceptual mismatch.
- **Per-target subtree split** (`runtime.universal` + `runtime.kubernetes` + `runtime.compose` + `runtime.nomad`). Rejected by D30 (see below) — would force module bodies to do target-specific reads and re-introduces the lowest-common-denominator pressure on the universal tree.

**Rationale:** Kubernetes is the most expressive deploy substrate the project targets today. Building a runtime-agnostic abstraction before a second concrete runtime exists tends to produce abstractions that fit no runtime well. Picking k8s as the substrate keeps the field shapes legible and lets non-k8s runtimes derive — compose and nomad are both close enough to k8s on the relevant axes (workload identity, naming, hierarchy, DNS-like service discovery) that a mapping is mechanical. Cross-runtime portability for *ecosystem-supplied resolutions* (URLs, peer addresses, connection strings) flows through Claim `#status` (015 CL-D15), not through `runtime` field abstractions — a richer channel that doesn't need the runtime fields to be portable.

**Cross-references:** 016 D30 (no `target.<runtime>` split); 014 D8 (matcher detects unmatched FQNs); 014 D9 (per-runtime transformer Modules); 015 CL-D15 (Claim `#status` as cross-runtime portability surface).

**Source:** Design conversation 2026-05-01 (platform-model brainstorm).

---

### D30: No `target.<runtime>` split inside `#ctx.runtime`

**Decision:** `#ctx.runtime` is a single tree of k8s-vocabulary fields (D29). It does **not** split into `runtime.universal` + `runtime.kubernetes?` + `runtime.compose?` + `runtime.nomad?` per-target subtrees. Module bodies read `#ctx.runtime.cluster.domain` etc. without runtime-aware conditionals.

**Alternatives considered:**

- **Per-target subtree.** Considered during the brainstorm: `#ctx.runtime` becomes `runtime.universal` for fields every runtime populates (release identity, route domain) plus `runtime.kubernetes` / `runtime.compose` etc. for runtime-specific subtrees, with exactly one subtree active per deploy. Rejected: splits the read surface — modules wanting to be portable must read `runtime.universal` only, and modules using k8s-specific fields must conditionalize on `runtime.kubernetes != _|_`. The split also doesn't earn anything that k8s-canonical + claim-based portability doesn't already give.

**Rationale:** With k8s-canonical (D29) and claim-based portability (`#status` from 015 CL-D15) carrying cross-runtime resolutions, the per-target subtree adds split-brain reading discipline without producing simpler portable code. The k8s-canonical tree stays legible across runtimes; non-k8s runtimes interpret the fields by mapping (D29 + 02-design.md "Non-Kubernetes Runtime Semantics"). The per-target subtree may become useful later if a non-k8s runtime needs structurally different facts that resist mapping; that's a 2nd-runtime-actually-shipping decision, not a now decision.

**Cross-references:** 016 D29 (k8s-canonical framing); 015 CL-D15 (Claim `#status`); 014 D9 (per-runtime transformer Modules).

**Source:** Design conversation 2026-05-01 (platform-model brainstorm — brainstorm gamed out the split, then collapsed back to k8s-canonical).

---

### D31: Drop the `#ComponentNames.hashes?` slot from this enhancement

**Decision:** The `#ComponentNames.hashes?` slot (with `configMaps?` and `secrets?` sub-maps) is removed from 016. `#ContextBuilder` no longer reserves a schema slot for content hashes of immutable ConfigMaps and Secrets. Transformers continue to compute and append hash suffixes on their own (the existing pre-016 behaviour). Modules cannot read a hash value through `#ctx`.

**Alternatives considered:**

- **Keep the reserved slot, populate via Go (Strategy B).** The earlier 016 design (carried forward from archived 008 D11/D12) reserved `hashes?` so the slot was schema-visible even though `#ContextBuilder` left it empty. Rejected for v1 of 016: no concrete module needs to read the hash at definition time, and a reserved-but-empty slot adds schema surface that consumers must guard against without paying back any module-author capability today.
- **Strategy A two-pass CUE evaluation.** Already deferred by archived 008 D12 / 016 OQ4; making the slot itself optional doesn't change that calculus.

**Rationale:** The hash continues to flow transformer-side; the rendered K8s manifest still ends up with `name-<hash>` for immutable resources. The only thing the schema slot would buy is a *module-readable* hash value, and no current module has a working pattern for that (the mc_java_fleet Backrest case in `modules/mc_java_fleet/components.cue:1875` works correctly with `secrets.backrestConfig` indirection — the transformer pipes the hashed name through without the CUE side ever spelling it out). Removing the slot keeps the 016 schema lean and matches the catalog's small-batch principle (Constitution IX). When a concrete use case surfaces — a module that must interpolate a hashed Secret name into an env var, an annotation, or a sibling component's reference — the slot can be reintroduced with a populating mechanism (Strategy A or B) chosen against the actual requirement.

**Supersedes:** Archived 008 D11 (centralised hash location), archived 008 D12 (Strategy B injection timing). Both are now no-ops as far as 016 is concerned; reintroduction is tracked by OQ4.

**Source:** User decision 2026-05-01 ("Lets remove the 'hashes?' field altogether from the enhancement for now. If it really is required we can add it back later.").

---

### D32: Per-component `#names` injection — `#ContextBuilder` writes `#ComponentNames` back into each component

**Decision:** `#ContextBuilder` produces two outputs instead of one: a `ctx` value (the existing `#ModuleContext` surface) and an `injections` map keyed by component name, where each entry is `{ #names: <that component's #ComponentNames> }`. `#ModuleRelease` unifies `injections` into `#module.#components` alongside `values → #config` and `ctx → #ctx`. Each `#Component` gains a `#names: #ComponentNames` definition field. A component body reads its own resourceName and DNS variants as `#names.resourceName` / `#names.dns.fqdn` without retyping its own map key. Cross-component reads still go through `#ctx.runtime.components[<otherKey>]`.

**Alternatives considered:**

- **Force `#ctx.runtime.components[<self-key>]` reads everywhere.** Rejected: every self-reference forces the author to retype the component's own key string, which duplicates the map key and breaks any time the component is renamed. The mc_java_fleet dynamic loop (`for _srvName, _c in #config.servers { "server-\(_srvName)": { ... #ctx.runtime.components["server-\(_srvName)"].dns.fqdn ... } }`) makes the redundancy especially visible.
- **`let` bindings inside the component body** (e.g. `let _names = #ctx.runtime.components["router"]`). Works today and has no CPU cost (CUE `let` is a memoised scope-local alias, not a function call), but the key string still has to be typed once per component. Useful as an interim — and remains useful for cross-component reads — but not the cleanest authoring story.
- **CUE `self` (aliasv2 experiment).** Rejected for v1: preview-only, not in the language spec, known stack-overflow regression on Kubernetes-shaped schemas (`cue-lang/cue#4228`), and even if stable it solves intra-struct lexical reference, not cross-document context injection — `#ContextBuilder` would still be required. See `05-cue-self-research.md` for the full evaluation.
- **Inject the full `#ctx` slice with extra helper fields.** Rejected: bloats every component scope with fields the author doesn't need; clearer to keep `#names` narrow and let `#ctx.runtime.components` stay the lookup surface for cross-component reads.

**Rationale:** Self-reference is the dominant access pattern (a component talks about its own name far more often than a peer's). Eliminating the self-key retype removes a class of refactor footguns (rename the map key, forget the lookup string) at the cost of one extra `for` loop in `#ContextBuilder`. The two builder outputs share a single `_componentNames` let binding, so `#names` and `#ctx.runtime.components` cannot drift — same value, two access paths. CPU cost is one additional struct iteration of the same shape that already populates `runtime.components`; no disjunction or unification blowup. Cross-component reads are intentionally left on `#ctx.runtime.components[<otherKey>]` because pulling another component's name *should* require naming that component — the current friction is the right friction there.

**Source:** Design discussion 2026-05-01 (016 follow-up after the user asked whether the self-reference could be reversed; `05-cue-self-research.md` consulted to rule out CUE `self` for v1).

---

## Open Questions

### OQ1 — `#TransformerContext` and `#ctx` overlap

`#ctx` and `#TransformerContext` overlap in several areas: release name, namespace, component name, label computation. They are computed independently for now; D15 defers the unification. **Why this matters:** drift between the two surfaces is silent. A divergence in naming or value (e.g. `resourceName` vs `name`) would confuse module authors who see both at different evaluation stages. **Revisit trigger:** before `#ctx` is widely adopted in transformers; ideally a follow-up enhancement decides one of (a) replace `#TransformerContext` with `#ctx`, (b) extend `#TransformerContext` to embed `#ctx.runtime`, or (c) keep separate with an explicit consistency contract.

### OQ2 — Bundle-level context

D20 defers cross-module references. **Why this matters:** platform teams composing bundles frequently need cross-module wiring (module A's service URL referenced in module B's config). Without bundle-level context, each module remains isolated. **Revisit trigger:** when `#BundleRelease` integration is designed.

### OQ3 — `platform` extension namespacing

D4 leaves the `platform` open struct flat. As more platform teams adopt `#ctx.platform`, uncoordinated key growth may require a namespacing convention (e.g. `platform: { myorg: { ... } }`) or a typed extension registry. **Revisit trigger:** first concrete collision between two platform teams' extensions.

### OQ4 — Reintroducing the content-hash channel

D31 removed the `#ComponentNames.hashes?` slot entirely; transformers continue to compute and bake hashes for immutable ConfigMaps and Secrets, but no module-readable hash value exists in `#ctx`. **Why this matters:** the hash is needed transformer-side for any immutable resource and the existing render still produces it; a module-readable channel would only be needed if a module wants to interpolate the hashed name into an env var, annotation, or a sibling component's reference. **Revisit trigger:** first concrete module that has to spell out the hashed resource name in CUE rather than rely on the transformer's indirect Secret/ConfigMap reference. At that point both the slot shape (where it lives in `#ComponentNames`) and the populating mechanism (Strategy A two-pass CUE eval vs Strategy B Go-side `FillPath`) can be chosen against a real requirement instead of being designed against a hypothetical one.
