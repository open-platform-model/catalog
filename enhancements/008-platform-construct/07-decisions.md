# Design Decisions

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for all design choices made during the module context, platform composition, and environment targeting design.

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

**Rationale:** The flat struct is the simplest possible extension point. Conventions can emerge organically and be formalised later if key collision or auditability becomes a problem.

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

### D8: Default `clusterDomain` — `"cluster.local"`

**Decision:** When `clusterDomain` is not supplied, it defaults to `"cluster.local"`. The default lives at the `#Platform.#ctx.runtime.cluster.domain` level.

**Alternatives considered:**

- No default, require explicit injection — rejected: would break all existing modules until every release file is updated; a backwards-incompatible requirement with no practical benefit

**Rationale:** `"cluster.local"` is the correct default for the vast majority of Kubernetes clusters. The value is overridable at the environment or platform level without any module change when a non-standard domain is needed.

**Source:** Design session 2026-03-25

---

### D9: `route` Field Optionality — `route?`

**Decision:** The `route` field inside `#ctx.runtime` is optional (`route?`). When no route domain is configured, the field is absent rather than set to an empty string or a sentinel value.

**Alternatives considered:**

- Default empty string — rejected: silently produces malformed URLs when modules interpolate the field without checking for its presence

**Rationale:** Not all clusters have an ingress or route domain. Making the field absent when not configured forces module authors to write explicit guards (`if #ctx.runtime.route != _|_`), which is safer than relying on a magic value that could produce subtly broken output.

**Source:** Design session 2026-03-25

---

### D10: `#ComponentNames` Cascading Derivation from `resourceName`

**Decision:** All DNS name variants inside `#ComponentNames` are derived from a single `resourceName` field via interpolation defaults. Overriding `resourceName` automatically propagates to all variants.

**Alternatives considered:**

- Independent computation for each DNS variant — rejected: creates four separate places to update when the naming strategy changes; makes future `nameOverride` support more complex

**Rationale:** A single source of truth for the base name (`resourceName`) means the entire cascade of DNS variants stays consistent automatically. The `metadata.resourceName` override (D13) targets `resourceName` only — all variants propagate automatically.

**Source:** Design session 2026-03-25

---

### D11: Content Hash Location — Centralised in `#ctx.runtime.components`

**Decision:** Content hashes for secrets and configMaps are stored at `#ctx.runtime.components[name].hashes`, not computed in individual transformers.

**Alternatives considered:**

- Keep hashes in transformers only — rejected: perpetuates the scattered, convention-dependent hash computation; provides no module-level access to hash values

**Rationale:** Centralising hash computation at `#ctx` provides a single lookup point for both module components and transformers, eliminates duplication, and aligns with the principle of one computation site per derived value.

**Source:** Design session 2026-03-25; `catalog/design/02-resource-name-override/`

---

### D12: Content Hash Injection Timing — Strategy B (Go-Side)

**Decision:** Content hashes are injected into `#ctx` by the Go pipeline after component spec resolution, before the transformer loop. This is Strategy B.

**Alternatives considered:**

- Strategy A: two-pass CUE evaluation — the first pass resolves specs, the second injects hashes back into `#ctx`; deferred because it adds CUE evaluation complexity without a current use case that requires it

**Rationale:** Strategy B avoids a circular CUE dependency (hashes require evaluated specs; specs require `#ctx`). It follows the existing `injectContext()` pattern and carries lower implementation risk. If a use case emerges where a component spec must reference its own hash before rendering, Strategy A can be revisited.

**Source:** Design session 2026-03-25

---

### D13: Resource Name Override — `metadata.resourceName` on `#Component`

**Decision:** Components can override their Kubernetes resource base name by setting an optional `resourceName` field on `#Component.metadata`. `#ContextBuilder` reads this field and passes it into `#ComponentNames.resourceName`, replacing the default `"{release}-{component}"`. All DNS variants cascade automatically.

**Alternatives considered:**

- Separate `#ComponentContext` struct on `#Component.#ctx` — rejected: creates a CUE cycle risk because `#ctx` flows down from `#ModuleRelease` to `#Module` to components, but the override input flows up from component to builder
- Override set directly on `#ctx.runtime.components[key].resourceName` from inside the module — rejected: self-referential; the module receives `#ctx` as input and cannot write to it without creating a dependency loop
- Separate `002-resource-name-override` design with `nameOverride`, `#resolvedNames`, and transformer helpers — rejected: the `#ctx` design already provides a centralized name computation via `#ComponentNames` and `#ContextBuilder`; a separate override mechanism adds unnecessary complexity

**Rationale:** Placing the override on component metadata keeps it as a clean input that `#ContextBuilder` reads before computing context. No cycle risk — metadata is set at module definition time, context is computed at release time. The existing `#ComponentNames` cascade handles propagation. This subsumes enhancement `002-resource-name-override` entirely.

**Source:** Design session 2026-04-11

---

### D14: `#ContextBuilder` Location — `catalog/core/v1alpha1/helpers/`

**Decision:** The `#ContextBuilder` helper is placed at `catalog/core/v1alpha1/helpers/context_builder.cue`.

**Alternatives considered:**

- Inline in `module_release.cue` — functional, but makes the release definition harder to read; the helpers pattern is already established by `#OpmSecretsComponent` and should be followed consistently

**Rationale:** Placing `#ContextBuilder` in the helpers package keeps it importable from `#ModuleRelease` without circular imports, independently testable as a CUE value, and consistent with the existing pattern for catalog-side computation helpers.

**Source:** Design session 2026-03-25; `#OpmSecretsComponent` precedent in `catalog/core/v1alpha1/helpers/`

---

### D15: `#TransformerContext` Relationship — Deferred

**Decision:** The relationship between `#ctx` and `#TransformerContext` is not resolved in this design. `#TransformerContext` is kept as-is.

**Alternatives considered:**

- Immediate replacement or extension of `#TransformerContext` — deferred; doing both simultaneously increases scope and risk

**Rationale:** Unifying `#ctx` and `#TransformerContext` is a separate design concern. `#TransformerContext` continues to work unchanged. A follow-up design must decide whether to replace, extend, or maintain the two as separate concerns.

**Source:** Design session 2026-03-25

---

### D16: `#Platform` is a Pure Capability Manifest

**Decision:** `#Platform` defines WHAT a platform can do (providers, context, capabilities). Runtime connection details (kubeContext, kubeConfig) are not part of `#Platform` — they are sourced externally at deploy time.

**Alternatives considered:**

- Including kubeContext/kubeConfig on Platform (RFC-0001 original) — rejected: Platform is served FROM the platform; it shouldn't carry its own connection details. Connection is a runtime concern resolved by the CLI/operator independently.
- Separate `#Platform` and `#ProviderComposition` constructs — rejected: Platform is the natural home for identity + capabilities

**Rationale:** `#Platform` answers "what can this target do?" not "how do I connect to it?" Coupling connection details into the capability manifest conflates two concerns with different lifecycles and security boundaries.

**Source:** User decision 2026-04-11; supersedes original RFC-0001 approach that included kubeContext.

---

### D17: `#Platform` Composes Providers; `#Provider` Is Not Renamed

**Decision:** `#Platform` is a new construct that composes one or more `#Provider` values. `#Provider` retains its identity and semantics unchanged.

**Alternatives considered:**

- Renaming Provider to something else — rejected: Provider has clear semantics and existing implementations (Kubernetes, K8up, cert-manager)
- Making Platform a subtype of Provider — rejected: Platform adds composition and identity which are not Provider concerns
- Eliminating Provider in favor of Platform — rejected: Provider is the right abstraction for transformer registration; Platform adds composition

**Rationale:** Provider is the building block. Platform composes building blocks. Clean separation of concerns.

**Source:** User decision 2026-03-29; recognized that capability modules are already providers.

---

### D18: Provider Composition via Ordered List

**Decision:** `#providers: [...provider.#Provider]` — an ordered list where position determines priority. Earlier providers take precedence when multiple transformers match the same component. `#composedTransformers` is produced by CUE unifying `#transformers` maps from all providers; FQN collisions produce CUE errors.

**Alternatives considered:**

- Named map (`[string]: provider.#Provider`) — rejected: maps are unordered in CUE; ordering is essential for transformer precedence
- Map with explicit `priority: int` field per entry — rejected: list position is simpler and more explicit
- Go-level merge with conflict resolution — rejected: CUE unification is the natural mechanism; FQN collisions are genuine errors; requires zero Go changes
- List-based transformer accumulation — rejected: maps with FQN keys match the existing pattern

**Rationale:** When a platform includes both OPM's `DeploymentTransformer` and a generic Kubernetes `DeploymentTransformer`, both match the same components. The platform author must control which one wins. An ordered list makes precedence explicit and visual: the first provider listed has highest priority. CUE's struct unification handles the map merge naturally — the FQN modulePath prefix guarantees key uniqueness across providers.

**Source:** User decision 2026-03-30; derived from platform diagram showing provider ordering.

---

### D19: `#Platform` Uses `#ctx` for Context — Replaces RFC-0001 `#PlatformContext`

**Decision:** Platform-level context uses `#ctx` with the same two-layer structure from the context design (`runtime` + `platform`). Replaces the earlier RFC-0001 `#PlatformContext` struct which had a different shape.

> **Clarification:** The context design defines `#PlatformContext` as the *schema type* for `#Platform.#ctx` (i.e., `#ctx: ctx.#PlatformContext`). This is not the same as the rejected RFC-0001 `#PlatformContext` — the new schema follows the `#ctx` two-layer pattern decided here.

**Alternatives considered:**

- Keep RFC-0001 `#PlatformContext` as a separate struct — rejected: creates a separate vocabulary for the same concept; platform context and module context should share a shape so CUE unification can merge them naturally
- Flat fields on Platform (`defaultDomain`, `defaultStorageClass`) — rejected: no clear merge path into `#ModuleContext`

**Rationale:** Using the same `#ctx` shape as `#Module` means platform-level defaults can be merged into the final `#ModuleContext` via CUE unification. No field-by-field mapping needed. Platform teams use `#ctx.platform` for extensions, same as in modules.

**Source:** User decision 2026-04-11.

---

### D20: Bundle-Level Context — Deferred

**Decision:** This design establishes module-level context only. Bundle-level context (cross-module references) is out of scope.

**Alternatives considered:**

- Include bundle context in this design — rejected: adds significant complexity before module-level context is proven; requires a bundle-level scope that does not yet exist in the schema

**Rationale:** Cross-module context references require a `#BundleRelease`-level scope that has not been designed. Attempting to build that scope here would expand the design beyond what is needed for the initial feature.

**Source:** Design session 2026-03-25

---

### D21: `#Environment` Is a New Construct

**Decision:** `#Environment` is a new catalog construct that targets a `#Platform` and contributes environment-level `#ctx` overrides. `#ModuleRelease` targets an environment, not a platform directly.

**Alternatives considered:**

- `#ModuleRelease` targets `#Platform` directly, with inline `#environment` for overrides (original approach) — rejected: conflates platform capabilities with environment specifics (namespace, route domain); forces release authors to reference both platform and environment config
- Environment as a field on Platform — rejected: one platform often hosts multiple environments; nesting environments inside platforms couples their lifecycles

**Rationale:** `#Platform` = "what can this cluster do?" `#Environment` = "how is this slice of the cluster used?" Different concerns, different constructs. Release authors target an environment and get both the platform's capabilities and the environment's context.

**Source:** User decision 2026-04-11.

---

### D22: `#Environment` Does Not Override `#config`

**Decision:** `#Environment` contributes only to `#ctx` (runtime context). It does not set or override `#config` (application values).

**Alternatives considered:**

- Allow environment-level value defaults — rejected: blurs the separation between deployment environment and application configuration; `#config` is the operator-supplied contract, `#ctx` is the runtime-supplied contract (D6)

**Rationale:** If environments could set values, the source of a config field becomes ambiguous (did it come from the release? the environment? the module default?). Keeping environments limited to `#ctx` preserves the clean ownership boundary.

**Source:** User decision 2026-04-11.

---

### D23: `#ModuleRelease` Targets Environment via `#env`

**Decision:** `#ModuleRelease` has an `#env` definition field that references the target `#Environment`. The release imports the environment package directly.

**Alternatives considered:**

- `#Config.environments` map with CLI flag lookup — rejected: adds unnecessary indirection; the release already knows its target environment at authoring time
- Regular field `environment:` — rejected: must be a definition (`#env`) to avoid appearing in exported output

**Rationale:** Direct import is the simplest path. The environment carries the platform reference and context, so the release gets everything it needs from a single import. No map lookup or CLI-side resolution needed.

**Source:** User decision 2026-04-11.

---

### D24: Context Hierarchy — Platform → Environment → Release

**Decision:** `#ctx.runtime` fields are populated through a layered override hierarchy: `#Platform.#ctx` → `#Environment.#ctx` → `#ModuleRelease` identity. Each layer can override the previous.

**Alternatives considered:**

- Flat merge with no precedence — rejected: ambiguous when platform and environment set the same field
- Release can override all context fields — accepted for namespace (`metadata.namespace` overrides env default); deferred for other fields to avoid release authors accidentally overriding platform facts

**Rationale:** The hierarchy matches the real-world ownership model: platform teams own cluster-level facts, environment operators own per-env config, release authors own per-module identity. Each layer has clear authority over its fields.

**Source:** User decision 2026-04-11.

---

### D25: Inline `#environment` on `#ModuleRelease` Superseded by `#Environment`

**Decision:** The earlier inline `#environment` field on `#ModuleRelease` (with `clusterDomain` and `routeDomain`) is replaced by the `#Environment` construct. The `#ContextBuilder` inputs change accordingly: the flat `{ clusterDomain, routeDomain? }` is replaced by typed `#platform: platform.#Platform` and `#environment: environment.#Environment` inputs. The `#ctx.platform` layer is populated by merging `#Platform.#ctx.platform` and `#Environment.#ctx.platform`, rather than starting as an empty struct. CLI `FillPath` injection for `#environment` is removed; environment is imported via CUE.

**Alternatives considered:**

- Keep both mechanisms — rejected: two ways to set the same fields creates confusion and precedence ambiguity

**Rationale:** `#Environment` is a strict superset of the inline `#environment` field. It adds platform reference, structured context hierarchy, environment identity, and namespace defaults. The `#ContextBuilder` receives richer, more structured inputs.

**Source:** User decision 2026-04-11.

---

### D26: Platform Definition Lives in `core/v1alpha1/platform/platform.cue`

**Decision:** New package `platform` in the core directory, following the existing pattern (provider, matcher, component each have their own package).

**Alternatives considered:**

- Adding to existing provider package — rejected: Platform is a construct that uses Provider, not a variant of Provider
- Adding to a new `infrastructure` package — rejected: overcomplicates the package structure

**Rationale:** Follows the one-construct-per-package convention established by component, module, policy, provider.

**Source:** Design discussion 2026-03-29.

---

### D27: Each Platform and Environment Is Its Own CUE Package

**Decision:** Platforms defined as standalone CUE packages in `.opm/platforms/<name>/platform.cue`, each exporting `#Platform`. Environments defined as standalone CUE packages in `.opm/environments/<env>/environment.cue`, each exporting `#Environment`. Environments import the specific platform they target.

**Alternatives considered:**

- Shared `platforms` / `environments` maps in a single `package opm` — rejected: forces all platforms/environments to be loaded together; prevents individual imports
- Single file for all platforms/environments — rejected: doesn't scale; makes per-environment imports awkward

**Rationale:** Package-per-entity follows CUE conventions and enables a clean import chain: Platform ← Environment ← Release. Each entity has its own imports without collision. Environments can be published as CUE modules and shared across teams.

**Source:** User decision 2026-04-11.

---

### D28: Matcher Receives `#provider` Unchanged — No Platform Awareness

**Decision:** `#MatchPlan` still takes `#provider: provider.#Provider`. The platform's `#provider` computed field is passed to it. The matcher has no knowledge of platform composition.

**Alternatives considered:**

- Making the matcher aware of platforms — rejected: the matcher's job is matching transformers to components. Composition is a layer above.

**Rationale:** Separation of concerns. The matcher is a pure function: given a provider and components, compute matches. How the provider was assembled is irrelevant.

**Source:** Design discussion 2026-03-29.

---

### D29: `#Provider` Gains a `type` Field — Homogeneous Platform Type

**Decision:** Providers declare their platform type via `metadata.type` (e.g., `"kubernetes"`, `"docker-compose"`). All providers in a Platform must share the same type.

**Alternatives considered:**

- No type field; rely on labels (`"core.opmodel.dev/platform": "container-orchestrator"`) — rejected: labels are informational; type is structural and should be enforced
- Type on Platform only, not Provider — rejected: a Provider is inherently tied to a platform type; making this explicit prevents composing incompatible providers

**Rationale:** A Kubernetes backup transformer cannot be composed with a Docker Compose provider. The `type` field makes this constraint explicit and CUE-enforceable. The Platform's `type` field validates against all providers' `metadata.type`.

**Source:** User decision 2026-03-30; derived from platform diagram showing `type: kubernetes` on all providers.

---

### D30: `capabilities` String List Remains Informational

**Decision:** The `capabilities: [...string]` field in platform context is for human/CLI informational use. The actual capability is expressed by the presence of a provider in `#providers`.

**Alternatives considered:**

- Deriving capabilities from provider metadata — deferred: adds complexity without clear benefit in v1
- Removing capabilities from platform context — rejected: it's useful for CLI display and filtering

**Rationale:** Two systems: strings for UI, providers for rendering. They can coexist without confusion.

**Source:** Design discussion 2026-03-29.
