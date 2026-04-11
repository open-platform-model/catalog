# Design Decisions — `#Platform`, `#Environment` & Provider Composition

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for the `#Platform` construct, `#Environment` construct, and provider composition enhancement. Decisions are append-only.

---

## Decisions

### D1: Platform composes Providers; Provider is not renamed

**Decision:** `#Platform` is a new construct that composes one or more `#Provider` values. `#Provider` retains its identity and semantics unchanged.

**Alternatives considered:**

- Renaming Provider to something else — rejected: Provider has clear semantics and existing implementations (Kubernetes, K8up, cert-manager)
- Making Platform a subtype of Provider — rejected: Platform adds composition and identity which are not Provider concerns
- Eliminating Provider in favor of Platform — rejected: Provider is the right abstraction for transformer registration; Platform adds composition

**Rationale:** Provider is the building block. Platform composes building blocks. Clean separation of concerns.

**Source:** User decision 2026-03-29; recognized that capability modules are already providers.

---

### D2: Provider composition uses CUE struct unification

**Decision:** `#composedTransformers` is produced by CUE unifying `#transformers` maps from all providers. FQN collisions produce CUE errors.

**Alternatives considered:**

- Go-level merge with conflict resolution — rejected: CUE unification is the natural mechanism; FQN collisions are genuine errors; requires zero Go changes
- List-based transformer accumulation — rejected: maps with FQN keys match the existing pattern

**Rationale:** CUE's struct unification is designed for exactly this — merging maps with disjoint keys. The FQN modulePath prefix guarantees key uniqueness across providers.

**Source:** Design discussion 2026-03-29.

---

### D3: Platform is a pure capability manifest — no runtime connection details

**Decision:** `#Platform` defines WHAT a platform can do (providers, context, capabilities). Runtime connection details (kubeContext, kubeConfig) are not part of `#Platform` — they are sourced externally at deploy time.

**Alternatives considered:**

- Including kubeContext/kubeConfig on Platform (RFC-0001 original) — rejected: Platform is served FROM the platform; it shouldn't carry its own connection details. Connection is a runtime concern resolved by the CLI/operator independently.
- Separate `#Platform` and `#ProviderComposition` constructs — rejected: Platform is the natural home for identity + capabilities

**Rationale:** `#Platform` answers "what can this target do?" not "how do I connect to it?" Coupling connection details into the capability manifest conflates two concerns with different lifecycles and security boundaries.

**Source:** User decision 2026-04-11; supersedes original RFC-0001 approach that included kubeContext.

---

### D4: `#providers` is an ordered list — SUPERSEDED by D10

**Decision:** Originally `#capabilityProviders` was a named map. Superseded by D10 (ordered list).

**Source:** Design discussion 2026-03-29.

---

### D5: Matcher receives `#provider` unchanged — no Platform awareness

**Decision:** `#MatchPlan` still takes `#provider: provider.#Provider`. The platform's `#provider` computed field is passed to it. The matcher has no knowledge of platform composition.

**Alternatives considered:**

- Making the matcher aware of platforms — rejected: the matcher's job is matching transformers to components. Composition is a layer above.

**Rationale:** Separation of concerns. The matcher is a pure function: given a provider and components, compute matches. How the provider was assembled is irrelevant.

**Source:** Design discussion 2026-03-29.

---

### D6–D7: Moved to enhancement 006

Decisions about `requiredClaims`/`optionalClaims` on `#Transformer` and `#declaredClaims` on `#Provider` are owned by [enhancement 006](../006-claim-primitive/).

---

### D8: Platform definition lives in `core/v1alpha1/platform/platform.cue`

**Decision:** New package `platform` in the core directory, following the existing pattern (provider, matcher, component each have their own package).

**Alternatives considered:**

- Adding to existing provider package — rejected: Platform is a construct that uses Provider, not a variant of Provider
- Adding to a new `infrastructure` package — rejected: overcomplicates the package structure

**Rationale:** Follows the one-construct-per-package convention established by component, module, policy, provider.

**Source:** Design discussion 2026-03-29.

---

### D9: `capabilities` string list in PlatformContext remains informational

**Decision:** RFC-0001's `capabilities: [...string]` in `#PlatformContext` is for human/CLI informational use. The actual capability is expressed by the presence of a provider in `#capabilityProviders`.

**Alternatives considered:**

- Deriving capabilities from provider metadata — deferred: adds complexity without clear benefit in v1
- Removing capabilities from PlatformContext — rejected: it's useful for CLI display and filtering

**Rationale:** Two systems: strings for UI, providers for rendering. They can coexist without confusion.

**Source:** Design discussion 2026-03-29.

---

### D10: `#providers` is an ordered list, not a named map (supersedes D4)

**Decision:** `#providers: [...provider.#Provider]` — an ordered list where position determines priority. Earlier providers take precedence when multiple transformers match the same component.

**Alternatives considered:**

- Named map (`[string]: provider.#Provider`) — rejected: maps are unordered in CUE; ordering is essential for transformer precedence
- Map with explicit `priority: int` field per entry — rejected: list position is simpler and more explicit

**Rationale:** When a platform includes both OPM's `DeploymentTransformer` and a generic Kubernetes `DeploymentTransformer`, both match the same components. The platform author must control which one wins. An ordered list makes precedence explicit and visual: the first provider listed has highest priority.

**Source:** User decision 2026-03-30; derived from platform diagram showing provider ordering.

---

### D11: `#Provider` gains a `type` field

**Decision:** Providers declare their platform type via `metadata.type` (e.g., `"kubernetes"`, `"docker-compose"`). All providers in a Platform must share the same type.

**Alternatives considered:**

- No type field; rely on labels (`"core.opmodel.dev/platform": "container-orchestrator"`) — rejected: labels are informational; type is structural and should be enforced
- Type on Platform only, not Provider — rejected: a Provider is inherently tied to a platform type; making this explicit prevents composing incompatible providers

**Rationale:** A Kubernetes backup transformer cannot be composed with a Docker Compose provider. The `type` field makes this constraint explicit and CUE-enforceable. The Platform's `type` field validates against all providers' `metadata.type`.

**Source:** User decision 2026-03-30; derived from platform diagram showing `type: kubernetes` on all providers.

---

### D12: `#Platform` uses `#ctx` for context (replaces `#PlatformContext`)

**Decision:** Platform-level context uses `#ctx` with the same two-layer structure from enhancement 003 (`runtime` + `platform`). Replaces the earlier `#PlatformContext` struct.

**Alternatives considered:**

- Keep `#PlatformContext` as a separate struct — rejected: creates a separate vocabulary for the same concept; platform context and module context should share a shape so CUE unification can merge them naturally
- Flat fields on Platform (`defaultDomain`, `defaultStorageClass`) — rejected: no clear merge path into `#ModuleContext`

**Rationale:** Using the same `#ctx` shape as `#Module` (enhancement 003) means platform-level defaults can be merged into the final `#ModuleContext` via CUE unification. No field-by-field mapping needed. Platform teams use `#ctx.platform` for extensions, same as in modules.

**Source:** User decision 2026-04-11.

---

### D13: `#Environment` is a new construct — deployment target for `#ModuleRelease`

**Decision:** `#Environment` is a new catalog construct that targets a `#Platform` and contributes environment-level `#ctx` overrides. `#ModuleRelease` targets an environment, not a platform directly.

**Alternatives considered:**

- `#ModuleRelease` targets `#Platform` directly, with inline `#environment` for overrides (enhancement 003 original) — rejected: conflates platform capabilities with environment specifics (namespace, route domain); forces release authors to reference both platform and environment config
- Environment as a field on Platform — rejected: one platform often hosts multiple environments; nesting environments inside platforms couples their lifecycles

**Rationale:** `#Platform` = "what can this cluster do?" `#Environment` = "how is this slice of the cluster used?" Different concerns, different constructs. Release authors target an environment and get both the platform's capabilities and the environment's context.

**Source:** User decision 2026-04-11.

---

### D14: `#Environment` does not override `#config` (values)

**Decision:** `#Environment` contributes only to `#ctx` (runtime context). It does not set or override `#config` (application values).

**Alternatives considered:**

- Allow environment-level value defaults — rejected: blurs the separation between deployment environment and application configuration; `#config` is the operator-supplied contract, `#ctx` is the runtime-supplied contract (established in enhancement 003 D6)

**Rationale:** If environments could set values, the source of a config field becomes ambiguous (did it come from the release? the environment? the module default?). Keeping environments limited to `#ctx` preserves the clean ownership boundary.

**Source:** User decision 2026-04-11.

---

### D15: Each platform and environment is its own CUE package

**Decision:** Platforms defined as standalone CUE packages in `.opm/platforms/<name>/platform.cue`, each exporting `#Platform`. Environments defined as standalone CUE packages in `.opm/environments/<env>/environment.cue`, each exporting `#Environment`. Environments import the specific platform they target.

**Alternatives considered:**

- Shared `platforms` / `environments` maps in a single `package opm` — rejected: forces all platforms/environments to be loaded together; prevents individual imports
- Single file for all platforms/environments — rejected: doesn't scale; makes per-environment imports awkward

**Rationale:** Package-per-entity follows CUE conventions and enables a clean import chain: Platform ← Environment ← Release. Each entity has its own imports without collision. Environments can be published as CUE modules and shared across teams.

**Source:** User decision 2026-04-11.

---

### D16: `#ModuleRelease` targets environment via `#env`

**Decision:** `#ModuleRelease` has an `#env` definition field that references the target `#Environment`. The release imports the environment package directly.

**Alternatives considered:**

- `#Config.environments` map with CLI flag lookup — rejected: adds unnecessary indirection; the release already knows its target environment at authoring time
- Regular field `environment:` — rejected: must be a definition (`#env`) to avoid appearing in exported output

**Rationale:** Direct import is the simplest path. The environment carries the platform reference and context, so the release gets everything it needs from a single import. No map lookup or CLI-side resolution needed.

**Source:** User decision 2026-04-11.

---

### D17: Context hierarchy — Platform → Environment → Release

**Decision:** `#ctx.runtime` fields are populated through a layered override hierarchy: CUE defaults → `#Platform.#ctx` → `#Environment.#ctx` → `#ModuleRelease` identity. Each layer can override the previous.

**Alternatives considered:**

- Flat merge with no precedence — rejected: ambiguous when platform and environment set the same field
- Release can override all context fields — accepted for namespace (`metadata.namespace` overrides env default); deferred for other fields to avoid release authors accidentally overriding platform facts

**Rationale:** The hierarchy matches the real-world ownership model: platform teams own cluster-level facts, environment operators own per-env config, release authors own per-module identity. Each layer has clear authority over its fields.

**Source:** User decision 2026-04-11.

---

### D18: Enhancement 003 `#environment` on `#ModuleRelease` superseded by `#Environment`

**Decision:** Enhancement 003's inline `#environment` field on `#ModuleRelease` (with `clusterDomain` and `routeDomain`) is replaced by the `#Environment` construct from this enhancement. The `#ContextBuilder` inputs change accordingly.

**Alternatives considered:**

- Keep both mechanisms — rejected: two ways to set the same fields creates confusion and precedence ambiguity

**Rationale:** `#Environment` is a strict superset of the inline `#environment` field. It adds platform reference, structured context, and environment identity. The `#ContextBuilder` receives richer, more structured inputs.

**Source:** User decision 2026-04-11; evolution of enhancement 003 D8.
