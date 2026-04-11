# Design Package: `#Op` & `#Action` Primitives

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-11       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Op` as a slim schema base type for atomic operations and `#Action` as a full primitive that composes Ops into ordered, dependency-aware execution flows. Ops are tagged with `@op("...")` CUE attributes for runtime dispatch — CUE declares the schema, the OPM runtime (CLI or k8s controller) executes. Actions use `$after` fields for explicit step ordering, inspired by Hofstadter's `@task`/`@flow` model adapted to OPM's composition patterns.

Together, `#Op` and `#Action` complete the operational side of OPM's type system. Actions are consumed by Lifecycle (state transitions) and Workflow (on-demand execution).

## Documents

1. [01-problem.md](01-problem.md) — No primitive for executable operations; Lifecycle and Workflow have nothing to compose
2. [02-design.md](02-design.md) — Slim `#Op` base type with `@op` attributes; `#Action` primitive with `$after`-ordered steps
3. [03-decisions.md](03-decisions.md) — All design decisions with rationale and alternatives considered
4. [04-schema.md](04-schema.md) — New CUE definitions for `#Op`, `#Action`, `#Step`, and well-known Ops

## Applicability Checklist

- [x] `04-schema.md` — New CUE definitions for `#Op`, `#Action`, `#Step`, and well-known Ops
- [ ] `NN-pipeline-changes.md` — Go pipeline modifications
- [ ] `NN-module-integration.md` — Impact on module authors
- [ ] `NN-notes.md` — Deferred items and open questions

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `CONSTITUTION.md` (repo root) | Core design principles governing all changes in this repository |
| `catalog/docs/core/definition-types.md` | Full type taxonomy — Op and Action listed as draft primitives |
| `catalog/docs/core/primitives.md` | Primitive design docs — Op and Action draft descriptions |
| `catalog/docs/core/constructs.md` | Lifecycle and Workflow constructs that consume Actions |
| `catalog/enhancements/006-claim-primitive/` | `#Claim` primitive — parallel composition model for platform needs |
| `catalog/enhancements/006-claim-primitive/04-operational-claims.md` | Operational claims (backup/restore) that Actions would execute |
| `catalog/core/v1alpha1/component/component.cue` | `#Component` — composition pattern that `#Action` adapts for ordered execution |
| `catalog/core/v1alpha1/primitives/` | Existing primitive definitions — `#Op` base type would live here |
