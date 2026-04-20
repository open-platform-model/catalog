# Analysis: Design Flaws and Open Questions

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-19       |
| **Scope**   | Critique of 008 design against existing `catalog/`, `cli/`, `opm-operator/` |

## Context

Enhancement 003 (module-context) was archived and never merged. Enhancement 008 therefore builds new context infrastructure from scratch, not evolves an existing one. Current catalog has no `#ctx`, no `#environment` field on `#ModuleRelease`, no `clusterDomain` or `routeDomain` anywhere. Current CLI injects `#context.#moduleReleaseMetadata`, `#context.#componentMetadata`, and `#context.#runtimeName` per-transformer via `injectContext()` in `cli/pkg/render/execute.go`. Current `#Provider.metadata` has no `type` field. No `#Platform` or `#Environment` construct exists in the catalog. opm-operator has no Platform/Environment CRDs.

The findings below are numbered for cross-reference.

---

## Critical design gaps

### F1 — Priority is lost inside `#composedTransformers`

`#Platform.#composedTransformers` is built by unifying each provider's `#transformers` map keyed by FQN. CUE maps are unordered. D18 asserts "position determines priority" but unification collapses order into the map. The matcher receives a flat map; it has no way to recover which provider contributed which FQN, so the priority rule cannot be applied.

Resolutions to consider:

- Pass an ordered FQN list alongside the map (`#composedPriority: [...string]`)
- Have the matcher walk `#providers` directly in order, stopping at first match
- Record origin provider rank on each transformer value at composition time

**Tension:** CUE-native unification vs. ordered precedence. Current design cannot express both.

### F2 — Multi-match conflict resolution is punted twice

`04-platform.md` defers conflict rules to `06-module-integration.md`. `06-module-integration.md` does not define them. The canonical example — `opm.DeploymentTransformer` and `kubernetes.DeploymentTransformer` both matching the same component — has no specified resolver. This is the key scenario motivating ordered providers; leaving it undefined leaves the feature inoperable.

Options:

- "First provider wins" explicit rule in `#MatchPlan`
- Require transformers to declare mutual exclusion via labels
- Force platform authors to resolve by omitting duplicates

### F3 — `hashes` schema location contradicts Strategy B

D11 places `hashes?` inside `#ctx.runtime.components[name]` so components can reference them. D12 selects Strategy B, where Go injects hashes after component spec evaluation. A component spec cannot reference its own hash under Strategy B — the spec is frozen before injection. The schema advertises a capability the chosen implementation strategy cannot deliver.

Options:

- Move `hashes` out of module-level `#ctx` (keep inside `#TransformerContext` only)
- Commit to Strategy A (two-pass CUE evaluation)
- Document that `hashes` is populated for *observers* (other components, annotations) but not self-referential

### F4 — `metadata.type!` on `#Provider` is a silent breaking change

Adding a required `type!: string` to `#Provider.metadata` breaks every existing provider in `opm/`, `k8up/`, `cert_manager/`, `gateway_api/`, `kubernetes/` on CUE unification until each is updated. No default, no migration phase. Separately, `type: string` is unconstrained — `"kubernates"` typo is accepted silently and later fails platform homogeneity check with an opaque error.

Options:

- `type: *"kubernetes" | string` to avoid the break
- Constrained enum: `type: "kubernetes" | "docker-compose"` (closed list, maintained in core)
- Staged rollout: ship field as optional, flip to required in a follow-up

### F21 — `#ctx.platform` override is CUE unification, not override

`#ContextBuilder` (`03-schema.md:380`) merges platform extensions as `platform: #platform.#ctx.platform & #environment.#ctx.platform`. CUE `&` is unification. If `#Platform.#ctx.platform.defaultStorageClass: "standard"` and `#Environment.#ctx.platform.defaultStorageClass: "fast"` both set concrete values, unification fails — it does not override. The context hierarchy documented in `02-design.md:42-60`, `09-context-flow.md:78-92`, and D24 repeatedly promises "later layers override earlier" but the merge operator in `#ContextBuilder` cannot deliver that for any concrete field. Only fields declared as `*default | T` disjunction (currently only `cluster.domain` in `#PlatformContext.runtime.cluster`) actually support override. Every field the docs imply environments can override silently inherits the platform value or produces a CUE conflict.

Options:

- Define an explicit override merge helper instead of `&` (e.g., a `#OverrideMerge` taking `base` and `override`)
- Require all platform-layer fields to use `*default | T` disjunction; document the constraint
- Rewrite the override narrative: platform layer is *defaults only*; any field that might be env-specific must never be set concretely on `#Platform`

### F22 — Provider homogeneity (D29) is prose-only, not schema-enforced

D29 declares all providers inside a `#Platform` must share the same `type`. Schema at `03-schema.md:246` is `#providers!: [...provider.#Provider]` — no constraint linking `#Platform.type` to `#providers[].metadata.type`. Nothing stops composing a Kubernetes provider with a Docker Compose provider in the same platform. The rule exists only as documentation. CUE can express this constraint in one line (`for p in #providers { p.metadata.type: type }`) but the schema omits it.

Options:

- Add the constraint explicitly in `#Platform` schema
- Replace homogeneity with per-provider scoping in a future design (see F17)

### F5 — CLI `--environment` flag vs. hardcoded `#env` import

`06-module-integration.md` shows `opm release apply ... --environment prod` and `opm bundle apply ... --environment prod`. Release file declares `#env: env.#Environment` via CUE import. There is no mechanism for the CLI flag to override the import. Either:

- CLI flag is ignored (release author hardcodes env, flag is documentation-only)
- CLI must `FillPath` over a definition, contradicting the "no FillPath injection" claim in 06

For bundles, the problem is sharper: the same bundle definition needs to deploy to dev, staging, prod. Hardcoding `#env` in the bundle file defeats that.

Options:

- Release files leave `#env` abstract; CLI resolves via flag + `.opm/environments/` lookup
- Release files pin environment; CLI flag is informational only
- Two modes: pinned releases (import-bound) and parameterized releases (flag-bound)

### F6 — `#TransformerContext` remains a parallel context

Module authors read `#ctx.runtime.release.name`. Transformers read `#context.#moduleReleaseMetadata.name`. Same data, two paths, no consistency contract. D15 and N2 defer the reconciliation. The catalog will ship both vocabularies simultaneously. Transformers touching ingress/route resources cannot read `route.domain` from their own context — they must receive it through component spec values, reintroducing the same plumbing problem `#ctx` is meant to solve.

Options:

- Block 008 on `#TransformerContext` unification design
- Ship 008 with an explicit adapter: `#TransformerContext` embeds or references `#ctx.runtime`
- Ship as-is, accept drift, document it loudly

---

## Structural concerns

### F7 — `.opm/` import path is unstated

Examples use `opmodel.dev/config@v1/.opm/environments/dev`. `.opm/` typically lives in a user workspace (e.g., `releases/`), not inside a published CUE module. For the import chain to work, `.opm/` must be inside a published CUE module *or* the releases workspace must declare it as a local package. Neither is spelled out. This affects whether every environment change requires a module publish cycle and whether `.opm/` is per-repo or workspace-wide.

### F8 — Publishing environments as CUE modules

`05-environment.md` suggests publishing environments as shared CUE modules. Semver versioning a live deployment target is semantically odd — an environment represents the current state of a slice of infrastructure, not a versioned contract. Registry sprawl (one module per environment per team) compounds the issue.

Alternatives:

- Local-only environment packages (never published)
- Single `environments/` module with a map of envs
- Environments as values, not modules (loaded via file path, not import)

### F9 — Namespace override mechanics are unspecified

Current `#ModuleRelease.metadata.namespace!: string` is required. Environment contributes `release.namespace`. For the release to inherit the environment default, `metadata.namespace` must become optional with env-side fallback. The change to `#ModuleRelease.metadata` is not described in `03-schema.md`. Small but load-bearing.

### F23 — Component name typos in `#ctx.runtime.components` silently produce broken output

`#RuntimeContext.components: [compName=string]: #ComponentNames` (`03-schema.md:164`) is an open pattern constraint. A module author who writes `#ctx.runtime.components.jellyfon.dns.fqdn` (typo: `jellyfon` instead of `jellyfin`) produces a valid CUE expression typed as `string`. At release time, `#ContextBuilder` iterates only real component keys from `#module.#components` and never populates `_releaseName` / `_compName` for the typo. The typo'd expression still evaluates — to `"-jellyfon..svc.cluster.local"` or similar malformed garbage — and renders into the output. No vet-time error, no render-time error. The bug only surfaces when the resulting Kubernetes resource misbehaves.

Options:

- Close `#RuntimeContext.components` to the exact set of component keys via `for` comprehension at `#ContextBuilder` output (replace the pattern constraint with explicit keys)
- Add a module-level validator that rejects unknown component references in `#ctx.runtime.components.*`
- Accept the footgun; document clearly and rely on downstream linting

### F24 — Release import pulls full Platform + Providers transitive closure into every release

Release files import `#env`, which imports `#platform`, which embeds `#providers: [...]` — the full list of provider values with all their `#transformers` maps. Every `#ModuleRelease` CUE evaluation now pulls the entire platform capability graph into scope, even for a release that uses a handful of resources. Evaluation cost scales with platform size, not with module size. Error blast radius expands: a bad transformer in one capability provider breaks release evaluation for every module targeting that platform. Today a release only pulls the module it deploys.

Options:

- Split `#Platform` into an authoring-time manifest (light) and a render-time bundle (heavy); releases import only the manifest, CLI loads the bundle separately
- Cache composed provider at platform-build time and import a thin reference from releases
- Accept the cost; measure eval time on a realistic platform (20+ providers) before shipping

### F10 — `resourceName` uniqueness is not enforced

The `metadata.resourceName` override removes the `{release}-{component}` uniqueness guarantee. Two components setting the same `resourceName` produce two Kubernetes resources with the same name. CUE unification does not catch this. No schema-level constraint enforces uniqueness of resolved `resourceName` across a module's components.

Options:

- Add a module-level constraint validating uniqueness of `resourceName` across `#components`
- Document the footgun; rely on `cue vet` to surface duplicates at render time
- Require override to include a disambiguator (e.g., `resourceName: "{release}-\(key)"`)

---

## Lower-severity issues

### F11 — `capabilities: [...string]` (D30) guarantees drift

D30 keeps `capabilities` as informational strings alongside `#providers`. "Two systems: strings for UI, providers for rendering." A platform with `k8up.#Provider` but `capabilities: ["cert-manager"]` silently misleads CLI users. Derivation from providers is cheap in CUE. Choosing drift is a choice; call it out explicitly in release notes.

### F12 — Three spellings of the same concept

`#env` on `#ModuleRelease`, `#environment` as `#ContextBuilder` input, `#Environment` as the construct name. Pick one root (e.g., `#env` everywhere) and apply consistently.

### F13 — D7 vs. D12 weaken the CUE-native rationale

D7 chose CUE-side computation for discoverability and testability. D12 punches a Go-side hole for hashes. Doesn't invalidate D7 but weakens its rationale for the one sub-struct most sensitive to timing. Document why hashes are the exception and confirm no other `#ctx` fields will follow the same pattern.

### F14 — `#ContextBuilder` component iteration cycle risk

`#ContextBuilder` passes `#components: [string]: _` (pre-unification) and reads `comp.metadata.resourceName`. Safe when `resourceName` is a CUE literal at module-definition time. Breaks if an author derives it from `#config` — `#config` is not filled until after `#ctx` is computed, producing a cycle. Needs a schema guard: `metadata.resourceName` must be concrete without `#config` inputs.

### F15 — `.opm/` bootstrapping is unspecified

Where does the first `.opm/platforms/` template come from? An `opm platform init` command is implied by the `opm platform capabilities` and `opm environment list` commands but never specified. Compare to how existing providers (`gateway_api`, `k8up`) are laid out.

### F16 — opm-operator touchpoint is silent

No Platform or Environment CRDs exist in opm-operator. If runtime platform/env state becomes controller-observable (e.g., watched to reconcile capability changes on installed operators), the schema today binds only authoring-time shapes. Not a flaw of 008's scope, but worth declaring as an explicit non-goal: controller stays out of platform/environment resolution.

### F17 — `type` as homogeneity key blocks hybrids

D29: all providers in a platform must share `type: "kubernetes"`. Blocks hypothetical cross-type platforms (e.g., k8s + serverless). Intentional today. Flag as explicit non-goal so future hybrid platforms don't get blocked on a reviewer reading D29 literally.

### F18 — D16 elides domain-reality overlap with connection

D16 claims `#Platform` is a pure capability manifest, no connection details. But cluster domain *is* on `#PlatformContext.runtime.cluster` — and cluster domain is connection-adjacent (it's a property of how the cluster was installed, not an abstract capability). Route domain on `#PlatformContext` is also mildly wrong — ingress controllers can be swapped, changing the route domain without changing capabilities.

Options:

- Move `route.domain` off `#PlatformContext` entirely; keep only on `#EnvironmentContext`
- Keep cluster domain on platform but document that it straddles capability/connection
- Redraw the line: capability = provider set; everything else is environment

### F19 — `#env` grows a second resolver surface in the CLI

Current CLI loader resolves `#module`. New `#env` path adds a second import resolution surface. Could share resolver logic cleanly; could also diverge if not deliberately unified. Call out in implementation tasks.

### F20 — 006 / 007 / 008 merge ordering is unstated

008 reserves `#declaredClaims`, `#composedOffers`, `#satisfiedClaims` on `#Platform` but delegates implementation to 006 and 007. If 008 ships first, `#Platform` ships with reserved-but-unimplemented fields. If 006/007 ship first, they modify a construct that does not yet exist. Not a design flaw, but a sequencing risk that deserves an explicit merge order in the proposal.

---

## Tensions worth naming

| Tension | Position A | Position B | Status |
| --- | --- | --- | --- |
| Provider precedence | ordered `#providers` list (D18) | FQN-keyed map via unification | both claimed; schema incomplete |
| Context computation | CUE-side (D7) | Go-side (D12, for hashes) | hybrid without consistency contract |
| `#TransformerContext` vs `#ctx` | unify now | defer (D15) | ships two vocabularies |
| Environment selection | imported package in release file | CLI flag at deploy time | mechanism missing for bundles |
| `hashes` location | module-level `#ctx` (D11) | transformer-level only | D11 + D12 in conflict |
| Platform extension override | documented override (D24) | CUE `&` unification (03-schema:380) | override claim not expressible with chosen operator |
| Provider type homogeneity | enforced (D29) | unconstrained list (03-schema:246) | rule is prose, not schema |
| Release evaluation scope | module-only (today) | module + full platform graph (008) | transitive pull not acknowledged |

---

## Open questions

### Q1 — Accept schema gap on priority encoding, or block 008?

F1 and F2 together mean provider ordering is documented but not expressible. Should 008 block on defining an ordered resolver (either via a parallel priority list or by teaching `#MatchPlan` to walk `#providers`), or accept that priority is advisory and "first to render wins" in Go code?

### Q2 — Drop `hashes` from module-level `#ctx`, or commit to Strategy A?

F3. The D11 / D12 contradiction forces a choice. Dropping `hashes` from module-level context is smaller scope but gives up the "centralized hash lookup" benefit. Strategy A is the principled answer but adds CUE evaluation complexity without an urgent use case.

### Q3 — Who picks the environment — release author or deploy-time flag?

F5. Release-bound environments are simpler but break bundle parameterization. Deploy-time flags need a mechanism to override (or abstract-until-filled) the `#env` definition. Or both: pinned vs. parameterized releases as two distinct patterns.

### Q4 — Ship 008 with dual context or block on `#TransformerContext` design?

F6 and N2. The drift between `#ctx.runtime.release.name` and `#context.#moduleReleaseMetadata.name` is guaranteed once both ship. Blocking 008 on a `#TransformerContext` design delays the main feature. Shipping as-is locks in the drift pattern.

### Q5 — What is the intended merge order of 006 / 007 / 008?

F20. 008 reserves fields for 006 and 007. Which enhancement merges first? Proposal should state the order and specify what happens to the reserved fields in 008 if 006/007 slip.

### Q6 — Is `.opm/` workspace-wide or per-repo, and is it a published CUE module?

F7 and F15. Answer determines how platforms/environments bootstrap, whether environment changes require registry publishes, and how the import chain from release files to `.opm/environments/` resolves.

### Q7 — Should environments be CUE modules at all?

F8. Publishing an environment as a versioned CUE module is semantically awkward. Could be local-only packages, or a single map-of-envs module, or loaded by path instead of import. Shapes the operational model significantly.

### Q8 — What enforces `resourceName` uniqueness?

F10. Add a `#Module`-level CUE constraint, rely on `cue vet`, or require overrides to include a component-key disambiguator?

### Q9 — Does the catalog commit to no controller involvement in platform/environment resolution?

F16. Declaring this as an explicit non-goal would clarify where platform/environment state lives (CUE authoring time only) and would free opm-operator from future pressure to add CRDs.

### Q10 — Should `route.domain` be platform-level, environment-level, or both?

F18. D24 allows either. Practical guidance is missing: when does a platform set `route.domain` and when does it belong on the environment? A convention would reduce confusion.

### Q11 — How does `#ctx.platform` actually override across layers?

F21. The design promises override semantics but the `#ContextBuilder` uses CUE unification. Either the merge operator changes, or the override narrative is retracted, or platform-layer fields must be restricted to defaulted disjunctions only. Pick one and document it.

### Q12 — Should provider-type homogeneity be schema-enforced?

F22. One-line CUE constraint closes the gap. Omitting it leaves D29 as prose. Ship with the constraint, or document that homogeneity is advisory and tooling-enforced.

### Q13 — Should `#ctx.runtime.components` be closed to the module's component set?

F23. Open pattern produces silent typo bugs. Closing via `for`-generated keys tightens the contract at the cost of slightly more complex `#ContextBuilder` output.

### Q14 — What is the evaluation-cost budget for `#ModuleRelease`?

F24. Measure CUE eval time on a platform with 20+ providers before shipping. If the transitive pull is unacceptable, split manifest from render bundle.
