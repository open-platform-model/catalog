# Design Package: Operational Commodities via `#Trait` + `#Directive`

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-21       |
| **Authors** | OPM Contributors |

## Summary

Express commodity operational contracts — backup, and others of the same shape — using existing primitives plus one minimal addition. A component-level `#Trait` carries component-local facts; a module-level `#Directive` (new primitive, sibling to `#Rule` inside `#Policy`) carries cross-component orchestration. A new `#PolicyTransformer` scope renders the combined `(directive, matched components' traits)` into platform resources.

Proven on backup:

- `#BackupTrait` — per component: which volumes/paths to back up; app-specific quiescing hooks.
- `#BackupPolicy` (a `#Directive`) — per module: schedule, backend, retention, restore procedure.
- `#BackupScheduleTransformer` (a `#PolicyTransformer` in the K8up provider) — matches the directive + the matched components' traits → emits a K8up `Backend` + `Schedule` CR pair.

## Documents

1. [01-problem.md](01-problem.md) — Two-level concern split that backup actually needs; why existing primitives leave a gap at the module-orchestration layer
2. [02-design.md](02-design.md) — `#Directive` primitive, broadened `#Policy`, `#PolicyTransformer` scope, validation rules, platform-ctx namespacing convention
3. [03-backup-example.md](03-backup-example.md) — First worked example: `#BackupTrait`, `#BackupPolicy`, K8up `#BackupScheduleTransformer` (single-output cardinality)
4. [04-tls-example.md](04-tls-example.md) — Second worked example: `#CertificateResource`, `#CertificatePolicy`, cert-manager `#CertificateTransformer` (per-component cardinality; establishes the Resource-vs-Trait rule in D15)
5. [05-routing-example.md](05-routing-example.md) — Third worked example: Gateway API routes (`HTTPRoute` + siblings); cross-commodity decoupling observations
6. [06-policy-transformer.md](06-policy-transformer.md) — `#PolicyTransformer` schema, matching rules, provider registration
7. [07-rendering-pipeline.md](07-rendering-pipeline.md) — How policy-scope transformers fit into the render flow
8. [08-decisions.md](08-decisions.md) — All design decisions with rationale
9. [09-open-questions.md](09-open-questions.md) — Deferred items with revisit triggers

## Scope

### In scope

- The pattern of expressing operational commodity contracts via `#Trait` + `#Directive` + `#PolicyTransformer`.
- A single worked commodity: **backup** (K8up-backed, but provider-agnostic at the primitive layer).
- The minimal primitive, construct, and render-pipeline additions to make that pattern work.

### Out of scope

- Additional operational commodities (TLS certificates, Prometheus scraping, DNS publishing). The pattern is expected to generalize; confirming that is follow-up work.
- Data-plane contracts (typed value exchange, such as Postgres connection details or S3 endpoints injected into component specs). Structurally different problem; not addressed here.
- CRD lifecycle for operator-installed backup tools. Orthogonal; see `opm-operator/docs/research/crd-lifecycle-research.md`.

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/008-platform-construct/03-schema.md` | `#Platform.#ctx.platform` open struct — home for backup backends |
| `catalog/core/v1alpha1/primitives/` | Existing primitive definitions (gains `#Directive`) |
| `catalog/core/v1alpha1/policy/policy.cue` | `#Policy` construct (gains `#directives` field) |
| `catalog/core/v1alpha1/transformer/transformer.cue` | Existing `#Transformer` (gets sibling `#PolicyTransformer`) |
| `catalog/core/v1alpha1/provider/provider.cue` | `#Provider` (gains `#policyTransformers` field) |
| `catalog/opm/v1alpha1/traits/` | Home for new `#BackupTrait` (`operations/` subpackage) |
| `catalog/k8up/v1alpha1/` | K8up provider (gains `#BackupScheduleTransformer` as policy-scope) |
