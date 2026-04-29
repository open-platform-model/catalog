# Design Package: `#Module` Flat Shape with `#Claim` and `#Api` Primitives

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-28       |
| **Authors** | OPM Contributors |

## Summary

Restructures `#Module` into a flat, bounded set of nine fields and introduces two new primitives — `#Claim` and `#Api` — that together provide the demand/supply surface for OPM's commodity and specialty service ecosystem.

`#Module` keeps a small nucleus (`metadata`, `#config`, `debugValues`, `#components`) and gains five sibling slots: `#policies`, `#lifecycles`, `#workflows` (inward — operate on the module itself) and `#claims`, `#apis` (outward — visible to the platform and other modules). All slots are flat top-level fields. `#Action` is removed from the top level since it is consumed by Lifecycle and Workflow internally.

`#Claim` is a primitive that defines the shape of a need. The same primitive serves as both the type definition (when authored in a catalog or vendor package) and the request (when used inside a Module's `#claims`) via CUE unification. `#Claim` carries `apiVersion` and `path` metadata for traceability across module boundaries. There is no `type` string field — identity is structural through CUE references plus the metadata FQN.

`#Api` is a primitive that registers a Module's capability by embedding a `#Claim` as its `schema` field. One `#Api` embeds exactly one `#Claim` (1:1). `#Api` carries optional self-service catalog metadata and is purely declarative — the platform may use it to populate a self-service catalog, a deploy-time match cache, or both.

CRDs remain part of `#components` via the existing `#CRDsResource` pattern — `#Api` does not handle CRD installation.

## Documents

1. [01-problem.md](01-problem.md) — Module field-bloat risk; Resource/Claim litmus overlap; missing extension surface for ecosystem participants
2. [02-design.md](02-design.md) — Flat `#Module` shape; `#Claim` primitive with apiVersion+path identity; `#Api` primitive that embeds `#Claim`; matching by structural CUE references
3. [03-schema.md](03-schema.md) — CUE definitions for `#Module`, `#Claim`, `#Api` and a worked commodity definition triplet
4. [04-examples.md](04-examples.md) — App-with-claim, Operator-with-api, Specialty-vendor-claim, API-only Module
5. [05-litmus-updates.md](05-litmus-updates.md) — Updates to `docs/core/definition-types.md` litmus questions and decision flowchart
6. [06-decisions.md](06-decisions.md) — All design decisions with rationale and alternatives considered
7. [07-open-questions.md](07-open-questions.md) — Unresolved items with revisit triggers

## Applicability Checklist

- [x] `03-schema.md` — New CUE definitions for `#Claim`, `#Api`, and the revised `#Module`
- [x] `04-examples.md` — Worked examples for App, Operator, Specialty, API-only Modules
- [x] `05-litmus-updates.md` — Documentation updates to `definition-types.md`
- [x] `07-open-questions.md` — Deferred items and open questions
- [ ] `NN-pipeline-changes.md` — Go pipeline modifications (deferred until design accepted)
- [ ] `NN-module-integration.md` — Migration guidance for existing modules

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `CONSTITUTION.md` (repo root) | Core design principles governing all changes in this repository |
| `catalog/core/v1alpha1/module/module.cue` | Existing `#Module` definition — restructured by this enhancement |
| `catalog/core/v1alpha1/policy/policy.cue` | `#Policy` construct — referenced from `#Module.#policies` |
| `catalog/core/v1alpha1/primitives/resource.cue` | `#Resource` primitive — sibling primitive whose litmus is sharpened here |
| `catalog/core/v1alpha1/primitives/directive.cue` | `#Directive` primitive — pattern followed by `#Claim` (apiVersion + metadata + `#spec`) |
| `catalog/docs/core/definition-types.md` | Litmus test and decision flowchart updated by this enhancement |
| `catalog/docs/core/primitives.md` | Primitive reference — gains `#Claim` and `#Api` entries |
| `catalog/enhancements/006-claim-primitive/` | Archived predecessor — initial `#Claim` exploration; informs the demand-side shape |
| `catalog/enhancements/007-offer-primitive/` | Archived predecessor — supply-side counterpart; subsumed here as `#Api` |
| `catalog/enhancements/011-operational-commodities/` | `#Directive` + `#PolicyTransformer` — verb-flavor commodity pattern; complementary to this enhancement's noun-flavor `#Claim`/`#Api` |
| `catalog/enhancements/012-policy-redesign/` | Concurrent exploration of cross-component noun grammar; this enhancement provides the noun answer at module/component scope |
