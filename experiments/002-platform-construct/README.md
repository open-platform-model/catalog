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
20_transformer.cue          Stub #ComponentTransformer + #ModuleTransformer + #TransformerMap
21_module.cue               Stub #Module + #Component (sufficient for #defines + #claims + #components)
22_platform.cue             #PlatformBase + #Platform (strict) + #ModuleRegistration + #PlatformMatch
30_fixtures.cue             Hidden fixtures (_opmCoreModule, _postgresOperatorModule, _aivenOperatorModule, _k8upModule, _consumerWebApp, _consumerUnfulfilled)
tNN_*_tests.cue             9 positive test files
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
```

A schema regression in either positive or negative direction surfaces immediately.

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

- Apply Findings 1, 2, 3, 4, 5 to `enhancements/014-platform-construct/03-schema.md` so the documented schema matches the working form.
- When generating `catalog/core/v1alpha2/platform.cue`, copy from `22_platform.cue` (the working form), not from `03-schema.md` directly.
- Restore real type aliases (`#NameType` etc.) from the actual `core/v1alpha2/types.cue`.
- Replace stub `#Resource` / `#Trait` / `#Claim` / `#Module` / `#Component` with the real definitions from 015.
- Wire `#ctx: #PlatformContext` from 016 instead of the stubbed `#ctx?: _`.
- Phase 3 of the 014 plan — implementation in `core/v1alpha2/` — is gated on 015 transformer redesign + 016 context schemas landing first.
