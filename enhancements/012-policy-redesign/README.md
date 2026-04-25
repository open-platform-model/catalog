# Design Package: Rethinking `#Policy` for Cross-Component Concerns

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft — exploration |
| **Created** | 2026-04-22       |
| **Authors** | OPM Contributors |

## Summary

`#Module` composes one or more `#Component`. Components carry `#Resource` and `#Trait` — authoring-local facts. OPM today has no crisp home for concerns that span a set of components or the module as a whole. `#Policy` was introduced for this slot, broadened in 011 to carry `#PolicyRule` + `#Directive`. That broadening covers one flavor (operational commodities via `#Directive`) and leaves the cross-component "noun" flavor — shared networks, shared storage pools, shared identities — unmodeled.

This enhancement is an exploration, not a landed design. It catches up the record of a brainstorm comparing several ways to model cross-component concerns, records the KubeVela prior-art research that motivated the question, and lists open questions for the next round.

## Scope

### In scope

- Problem framing: three grammars of cross-component concern (noun, verb, constraint).
- Comparison of candidate models for expressing those grammars in OPM.
- Prior-art research: why KubeVela dropped `ApplicationScope` in favor of `Policy`, and what was lost.
- Open questions that gate convergence on one model.

### Out of scope

- A chosen design. 012 is divergent-phase; the next document in this line is expected to pick one approach and flesh it out.
- Detailed transformer-scope schema changes beyond illustration.
- Migration plan for existing `#PolicyRule` / `#Directive` usage.

## Documents

1. [01-problem.md](01-problem.md) — Why cross-component concerns are awkward today; the noun/verb/constraint grammar; gap analysis against 011.
2. [02-approaches.md](02-approaches.md) — Candidate models (A, C, D primary; B, E noted) with worked CUE examples and membership-authoring variants for each.
3. [03-kubevela-research.md](03-kubevela-research.md) — Timeline and stated rationale for KubeVela's removal of `ApplicationScope`; what Policy gained; what was lost; primary-source links.
4. [04-open-questions.md](04-open-questions.md) — Everything unresolved as of the first brainstorm.

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/011-operational-commodities/` | Prior enhancement — introduced `#Directive` + `#PolicyTransformer` for the verb flavor; does not address the noun flavor |
| `catalog/core/v1alpha1/policy/policy.cue` | Current `#Policy` construct — carries `#rules` + `#directives` |
| `catalog/core/v1alpha1/primitives/policy_rule.cue` | Current `#PolicyRule` primitive (governance; half-baked enforcement) |
| `catalog/core/v1alpha1/primitives/directive.cue` | Current `#Directive` primitive (operational orchestration) |
| `catalog/enhancements/006-claim-primitive/` (archived/draft) | Earlier attempt at a component-level primitive + `#Rule` + `#Orchestration` split |
| `catalog/enhancements/008-platform-construct/` | `#Platform.#ctx.platform` — where some shared nouns already live for commodities |
