# 002 — Platform Construct (`#Platform`) experiment

Sandbox for enhancement [014-platform-construct](../../enhancements/014-platform-construct/). Validates the `#Platform`, `#ModuleRegistration`, and `#PlatformMatch` schemas — including the D13–D16 decisions added during 014 review on 2026-05-01 — as a self-contained CUE module before lifting any of it into `core/v1alpha2/`.

## Self-contained

**Zero imports.** No `core/v1alpha2/*`, no other catalog modules, no CUE stdlib. Every file is in package `platform_construct`. UUIDs and FQNs are passed as opaque strings; the experiment proves the *platform-construct* mechanics, not UUID derivation.

`cue.mod/module.cue` declares `module: "opmodel.dev/experiments/platform_construct@v0"` with no `deps:` block, pinned to CUE language `v0.16.0`.

## Layout

```text
00_types.cue                Minimal regex-only type primitives
10_resource.cue             Stub #Resource (FQN-only surface)
11_trait.cue                Stub #Trait
12_claim.cue                Stub #Claim with #spec/#status
13_context.cue              Stub #TransformerContext (release + component identity)
20_transformer.cue          #ComponentTransformer (with #transform body) + #ModuleTransformer + #TransformerMap
21_module.cue               Stub #Module + #Component (incl. spec? for render-body reads)
22_platform.cue             #PlatformBase + #Platform (strict) + #ModuleRegistration + #PlatformMatch
24_module_release.cue       Thin #ModuleRelease wrapper ({#module, name, namespace, uuid?})
25_render.cue               #SatisfiesComponent predicate + #PlatformRender dispatch (pure-CUE matcher)
30_fixtures.cue             Hidden fixtures (modules, transformers w/ concrete render bodies, _webAppRelease)
tNN_*_tests.cue             12 positive test files
nNN_*_tests.cue             4 negative test files (each with own per-file tag)
```

## What each test asserts

### Positive (run with `-t test`)

| File | Anchor | What it proves |
|------|--------|----------------|
| t01 | D1 | Bare `#Platform` with empty `#registry` evaluates clean; every projection is empty |
| t02 | D2, D11, D16 | Single static registration; entry defaults `enabled: true`; FQN echoes through |
| t03 | DEF-D1 (015) | `#knownResources` / `#knownTraits` / `#knownClaims` aggregate `#defines.*` from registered Modules |
| t04 | DEF-D3 (015), D7 | `#composedTransformers` aggregates every enabled `#defines.transformers` |
| t05 | D12 | `#matchers.{resources,traits,claims}` reverse index keys correctly; single-fulfiller setup leaves `_invalid` empty |
| t06 | D8, D12 | `#PlatformMatch.matched` resolves consumer FQN demand; `unmatched` walker correctly flags an unfulfilled component-level Claim. Verifies the bug fix to the original `_demand.claims.module & _demand.claims.component` walker (CUE struct `&` is unification not union) |
| t07 | D13 | Multi-fulfiller diagnostic via `#PlatformBase`: `#matchers._invalid.claims` populates with offending FQN; `_invalid` lengths match expected counts |
| t08 | D14 | `enabled: false` hides the entry from every projection (`#known*`, `#composedTransformers`, `#matchers`) |
| t09 | D2, D15 (happy path) | Static + runtime writes to the same Id with disjoint fields unify cleanly; both writes survive into the merged value |
| t10 | D17, 014/05 satisfiesComponent | `#SatisfiesComponent` predicate cases: labels-only / resources-only / traits-only / combined / wrong-value / missing-key / empty-transformer-matches-everything |
| t11 | D17, D18, 014/05 dispatch | `#PlatformRender.#outputs` for `_webAppRelease` against opm-core-only platform yields exactly the deployment + service entries for `web`; manifest fields (apiVersion, kind, metadata.name/namespace, spec.replicas/image/ports/port) reflect concrete release + component values |
| t12 | D1 + D17 + D18 end-to-end | Full chain: registry → composedTransformers → matcher dispatch → rendered #outputs against the opm-core + postgres platform. Postgres' Claim-driven transformer is registered but does not appear in `#outputs` — proves 014 scope (Resource/Trait demand only; Claim demand is 015). Doubles as the showcase fixture: `cue eval -e '_pipelineFixture.#outputs' -t test ./...` dumps the rendered K8s manifest set |

### Negative (each with own per-file `@if(test_negative_<name>)` tag)

Run each with `! cue vet -c -t test_negative_<name> ./...` — cue vet MUST exit non-zero.

| File | Anchor | What it proves |
|------|--------|----------------|
| n01 | D3 | Two registered Modules' `#defines.resources` shipping the same FQN with different values fail CUE unification. Error: `conflicting values "<B-value>" and "<A-value>"` at `#knownResources."<fqn>".metadata.<field>` |
| n02 | D13 | Strict `#Platform` with two transformers fulfilling the same Claim FQN fails on the multi-fulfiller constraint. Error: `_n02_platform.#matchers._noMultiFulfiller: conflicting values 1 and 0` |
| n03 | D15 (sad path) | Static + runtime writes to the same Id with concrete-value disagreement fail. Error reports the conflicting values (`"0.5.0"` vs `"0.6.0"`) at the forcing test field; trace points at the two source declarations |
| n04 | D16 | Non-kebab Id (`opm_core` with underscore) is rejected by the `[Id=#NameType]` pattern constraint. Error: `_n04_platform.#registry.opm_core: field not allowed` (CUE folds the regex check into field-allowance — clearer "this Id isn't allowed in #registry" rather than a regex mismatch message) |

## Run

```bash
cd catalog/experiments/002-platform-construct

# Positives — must pass
cue fmt ./...
cue vet -c -t test ./...

# Negatives — each MUST fail (exit non-zero)
! cue vet -c -t test_negative_fqn_collision ./...
! cue vet -c -t test_negative_multi_fulfiller ./...
! cue vet -c -t test_negative_concurrent_conflict ./...
! cue vet -c -t test_negative_kebab_id ./...

# Showcase — dump the rendered K8s manifest set
cue eval -e '_pipelineFixture.#outputs' -t test ./...
```

A schema regression in either positive or negative direction surfaces immediately. The `cue eval` showcase prints the apps/v1 Deployment + v1 Service that the pure-CUE matcher produces from `_webAppRelease` against the demo platform.

## Pass 2 — `#ComponentTransformer.#transform` body, pure-CUE matcher dispatch, slim render pipeline

Pass 1 (t01–t09 + n01–n04) covered registration / index mechanics. Pass 2 adds the runtime side: the dispatch from `(transformer, component)` matches to rendered manifests, expressed entirely in CUE.

### What's new

- **`13_context.cue`** — `#TransformerContext` stub. Carries `release.{name, namespace}` and `component.name` — the minimum a transformer body needs to interpolate K8s metadata. Full `#ctx` with the runtime/platform two-layer shape lives in 016 / experiment 001.
- **`24_module_release.cue`** — `#ModuleRelease` thin wrapper. Pairs a `#Module` with deploy-time identity (release name + namespace + uuid). Honours D18 vocabulary without the `#ContextBuilder` machinery.
- **`25_render.cue`** — pure-CUE matcher dispatch:
  - **`#SatisfiesComponent`** — predicate. Walks `requiredLabels` / `requiredResources` / `requiredTraits` against a single component; returns `_ok: true` when every required key is present with the expected value. Mirrors the `satisfiesComponent` pseudocode in `enhancements/014-platform-construct/05-component-transformer-and-matcher.md`.
  - **`#PlatformRender`** — dispatch. For each `(transformer, component)` pair where the predicate holds, unifies the transformer's `#transform` body with concrete `#moduleRelease` / `#component` / `#context` and projects `output`. Result is `#outputs: [renderId=string]: _` keyed by `"<transformerFqn>/<componentName>"`. Name parallels `#transform.output`; deliberately avoids `bundle` since `#Bundle` is reserved for the planned bundle-of-Modules construct.
- **`20_transformer.cue`** — gains `#transform?: { #moduleRelease, #component, #context, output }` plus catalog-UI hints (`readsContext`, `producesKinds`).
- **`21_module.cue`** — `#Component` gains `spec?: _` so transformer bodies have something concrete to read.
- **`30_fixtures.cue`** — `_deploymentTransformer` and the new `_serviceTransformer` carry concrete `#transform.output` bodies emitting `apps/v1.Deployment` and `v1.Service`. `_consumerWebApp.web` carries a concrete `spec: {image, replicas, port}` plus the `#ExposeTrait`. `_webAppRelease` is the release fixture used by t11/t12.
- **t04 / t08 / t09** — transformer counts updated for the added `_serviceTransformer` in `_opmCoreModule`.

### What CUE expresses, what stays Go-side

The dispatch loop is a `(transformer × component)` comprehension guarded by `#SatisfiesComponent._ok`; each surviving pair becomes one entry in `#outputs` via `(t.#transform & {<concrete inputs>}).output`. CUE's struct comprehensions handle the iteration, the predicate is a CUE expression, and unification with the fixture's `if`-guarded body produces the rendered manifest at dispatch time.

What CUE cannot do here — and what stays Go-side: ordering between transformer firings, deduplication when two transformers emit the same `apiVersion/kind/name`, error aggregation across `#outputs`, and writing the rendered set to disk. None of those are matcher-correctness concerns; they're pipeline-orchestration concerns.

### Findings vs. 014 03-schema.md (pass 2)

Three new findings surfaced while wiring up the dispatch. Add to the lift checklist below.

#### 6. `#transform` body interpolations evaluate at fixture time → wrap in if-guards

A transformer fixture that writes `metadata.name: "\(#context.release.name)-\(#context.component.name)"` directly inside `output` fails `cue vet -c` at fixture-evaluation time because `#context.release.name` is `_|_` (the required field is unfilled). Production schema must wrap the body in if-guards that check input concreteness:

```cue
#transform: {
    #moduleRelease: _
    #component:     _
    #context:       #TransformerContext
    if #context.release.name != _|_
    if #context.component.name != _|_
    if #component.spec != _|_ {
        output: { ... interpolations using #context.* / #component.spec.* ... }
    }
}
```

The guards re-fire when the dispatcher unifies `t.#transform & {<concrete inputs>}` (verified — see Finding 7).

#### 7. Pattern-keyed `_ctxFor: [cName=string]:` defers dispatch unification → materialise eagerly

The dispatcher's per-component context map cannot be a pattern-only declaration:

```cue
// BROKEN — dispatch produces empty `output` even with concrete inputs.
_ctxFor: [cName=string]: #TransformerContext & { ... }
```

CUE evaluates `_ctxFor[cName]` lazily against the pattern, the `t.#transform & {#context: _ctxFor[cName]}` unification produces a deferred expression, and the fixture's if-guards never fire — `output` stays at the schema's `_`.

Fix: materialise `_ctxFor` eagerly with one entry per component:

```cue
_ctxFor: {
    for cName, _ in #moduleRelease.#module.#components {
        (cName): #TransformerContext & { ... }
    }
}
```

Concrete keys force CUE to resolve the context value at struct-construction time; the dispatcher's unification then operates on a concrete `#context` value and the if-guards fire.

#### 8. `#transform` input fields must be plain (`:`), not required (`!`)

Schema `#transform: { #moduleRelease!: _, #component!: _, #context!: #TransformerContext, output: _ }` looks correct on paper but fails: under strict mode an unfilled required field makes the enclosing struct evaluate as bottom, so `if t.#transform != _|_` in the dispatcher returns false at fixture time and the transformer is silently dropped from the loop.

Drop the `!` markers — the dispatcher provides all three concretely via unification, and the dispatch's per-pair unification fails loudly if any of them is missing or wrong-shaped:

```cue
#transform?: {
    #moduleRelease: _
    #component:     _
    #context:       #TransformerContext
    output:         _
}
```

## Findings vs. 014 03-schema.md

Two real bugs surfaced; both fixed in `22_platform.cue` and need to be lifted back into `enhancements/014-platform-construct/03-schema.md` before implementation.

### 1. List comprehension syntax (`if cond, t,` vs `if cond {t}`)

`03-schema.md` writes the `#matchers.{resources,traits,claims}` candidate lists as:

```cue
(fqn): [
    for _, t in #composedTransformers
    if t.kind == "ComponentTransformer"
    if t.requiredResources != _|_
    if t.requiredResources[fqn] != _|_
    t,
]
```

That is **not valid CUE** — list comprehensions require a brace-yield (`{t}` or `{f(t)}`) per iteration. The trailing `t,` form parses as a struct field list, not a list comprehension.

Working form (in this experiment):

```cue
(fqn): [
    for _, t in #composedTransformers
    if t.kind == "ComponentTransformer"
    if t.requiredResources != _|_
    if t.requiredResources[fqn] != _|_ {t},
]
```

### 2. `#known*` projection puts the comprehension inside the value-type clause

`03-schema.md` writes:

```cue
#knownResources: [FQN=string]: #Resource & {
    for _, reg in #registry
    if reg.enabled
    if reg.#module.#defines != _|_
    if reg.#module.#defines.resources != _|_
    for fqn, v in reg.#module.#defines.resources {
        (fqn): v
    }
}
```

The `#Resource & { for ... }` form treats the comprehension as a constraint **on each value**, not as a struct-builder for the parent map. The map stays empty regardless of what's in `#registry`.

Working form:

```cue
#knownResources: {
    [FQN=string]: #Resource
    for _, reg in #registry
    if reg.enabled
    if reg.#module.#defines != _|_
    if reg.#module.#defines.resources != _|_
    for fqn, v in reg.#module.#defines.resources {
        (fqn): v
    }
}
```

The pattern constraint and the comprehension live as siblings inside the struct, not as an `&`-clause on the value type.

### 3. Sibling-name shadow in `#PlatformMatch._demand.claims`

`03-schema.md` writes:

```cue
_demand: {
    claims: {
        module: { for _, claim in module.#claims { ... } }
        component: { for _, c in module.#components ... }
    }
}
```

Inside `_demand.claims.component`, `module` is a sibling field (the FQN map under `_demand.claims.module`), **not** the consumer Module input on `#PlatformMatch.module`. CUE lexical scoping resolves the sibling first; the comprehension iterates an empty map (or the wrong map) and the demand walker never sees the consumer's component-level Claims.

Working form: alias the input to a `let` binding, reference the alias inside the sub-comprehensions:

```cue
_demand: {
    let _consumer = module
    claims: {
        module: { for _, claim in _consumer.#claims { ... } }
        component: { for _, c in _consumer.#components ... }
    }
}
```

### 4. `_invalid` cannot iterate the typed published `#matchers.{resources,traits,claims}` fields

The published fields are typed `[FQN=string]: [...#ComponentTransformer]`. CUE's `for fqn, ts in resources` against a value with an open-list value type errors with `cannot range over resources (incomplete type list)` under `cue vet -c`.

Working form: pre-compute the candidate maps as `let` bindings (concrete) and iterate those instead:

```cue
let _resourceCandidates = { for fqn, _ in _resourceFqns { (fqn): [...] } }
resources: {[FQN=string]: [...#ComponentTransformer]} & _resourceCandidates
_invalid: resources: [for fqn, ts in _resourceCandidates if len(ts) > 1 {fqn}]
```

### 5. `unmatched` walker accesses undefined fields on typed sibling maps

The original walker used `if matched.claims[fqn] == _|_ || len(matched.claims[fqn]) == 0`. Under `cue vet -c`, accessing an undefined field on a typed sibling map (`matched.claims` typed `[FQN=string]: [...]`) raises `undefined field` rather than returning `_|_`.

Working form: pre-build a key-set struct from the matched map and check membership against it:

```cue
let _matchedClaimSet = { for fqn, _ in matched.claims { (fqn): _ } }
claims: [for fqn, _ in _claimDemand if _matchedClaimSet[fqn] == _|_ {fqn}]
```

## Lift checklist (when promoting to core/v1alpha2)

- Apply Findings 1, 2, 3, 4, 5 to `enhancements/014-platform-construct/03-schema.md` so the documented schema matches the working form. (Findings 1, 2, 4, 5 already lifted as of 2026-05-02; Finding 3 is correctly absent because the `_demand.claims` sub-tree is 015's responsibility.)
- Apply Findings 6, 7, 8 to `enhancements/014-platform-construct/05-component-transformer-and-matcher.md`:
  - Finding 6 — body if-guards become part of the documented authoring pattern for `#ComponentTransformer` fixtures.
  - Finding 7 — the matcher's per-component context construction must materialise eagerly, not via a pattern-keyed map. Update the matcher pseudocode in 05 to reflect this.
  - Finding 8 — `#transform` schema in 03-schema.md should not mark `#moduleRelease` / `#component` / `#context` as `!`-required.
- When generating `catalog/core/v1alpha2/platform.cue`, copy from `22_platform.cue` and `25_render.cue` (the working forms), not from `03-schema.md` / `05-component-transformer-and-matcher.md` directly.
- Restore real type aliases (`#NameType` etc.) from the actual `core/v1alpha2/types.cue`.
- Replace stub `#Resource` / `#Trait` / `#Claim` / `#Module` / `#Component` with the real definitions from 015.
- Wire `#ctx: #PlatformContext` from 016 instead of the stubbed `#ctx?: _`. Replace `#TransformerContext` stub with the production `#ctx`-derived shape.
- Phase 3 of the 014 plan — implementation in `core/v1alpha2/` — is gated on 015 transformer redesign + 016 context schemas landing first.
