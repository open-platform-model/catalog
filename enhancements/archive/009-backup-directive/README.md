# Design Package: `#Directive` Primitive — Backup & Restore

| Field       | Value                            |
| ----------- | -------------------------------- |
| **Status**  | Accepted (revised 2026-04-19)    |
| **Created** | 2026-04-02                       |
| **Authors** | OPM Contributors                 |

## Summary

Introduce `#Directive` as a new primitive type inside `#Policy`, alongside `#PolicyRule`. Directives describe operational behavior that the platform should execute on behalf of the module author. Unlike `#PolicyRule`, directives carry no enforcement semantics (`mode`, `onViolation`).

One well-known directive for K8up-based backup and restore:

- **`#K8upBackupDirective`** — a single unified directive with three sub-blocks. The K8up transformer reads the scheduling and repository fields to generate `Schedule` CRs. The OPM CLI reads the repository and restore fields to browse snapshots and run restore procedures. One directive, two consumers, no drift.

Per-component pre-backup quiescing (SQLite checkpoint, `pg_dump`, RCON `save-all`) is a component concern expressed as a separate trait, `#PreBackupHookTrait`, consumed by the K8up PreBackupPod transformer.

Restore is CLI-driven in v1. The CLI acquires a `coordination.k8s.io/v1` Lease during `opm restore run` so the controller yields while mutations are in flight.

## Landing plan

The `#Directive` primitive and its integration points (`#Policy.#directives`, `#Transformer.requiredDirectives`) are structural additions to `core/v1alpha1`. The specific directive and trait implementations — `#K8upBackupDirective`, `#PreBackupHookTrait`, and their transformers — ship in a new `opmodel.dev/opm_experiments/v1alpha1@v1` catalog module. Graduation into `opm/v1alpha1` is gated on the criteria in 07-open-questions.md Q4.

## Documents

1. [01-problem.md](01-problem.md) — Current duplication, component-level scope mismatch, restore gap, 006 complexity
2. [02-design.md](02-design.md) — `#Directive` primitive; `#Policy`/`#Transformer` changes; unified `#K8upBackupDirective`; `#PreBackupHookTrait`
3. [03-transformer-integration.md](03-transformer-integration.md) — Schedule and PreBackupPod transformers; matching and enrichment
4. [04-module-integration.md](04-module-integration.md) — Module author and release author experience; examples; migration
5. [05-cli-integration.md](05-cli-integration.md) — `opm backup`/`opm restore` commands; Lease-based pause; auth
6. [06-decisions.md](06-decisions.md) — Decision log, including the 2026-04-19 supersession of D4/D11/D14/D16
7. [07-open-questions.md](07-open-questions.md) — Unresolved questions blocking graduation from `opm_experiments`

## Cross-References

| Document | Purpose |
|---|---|
| `catalog/enhancements/archive/004-backup-trait/` | Predecessor — component-level two-trait backup design (archived) |
| `catalog/enhancements/006-claim-primitive/` | Broader design — `#Claim` + `#Orchestration` (Draft, not superseded) |
| `catalog/enhancements/007-offer-primitive/` | Supply-side counterpart to 006 (Draft, not superseded) |
| `catalog/core/v1alpha1/primitives/policy_rule.cue` | `#PolicyRule` — pattern followed by `#Directive` (minus enforcement) |
| `catalog/core/v1alpha1/policy/policy.cue` | `#Policy` construct (gains `#directives` field) |
| `catalog/core/v1alpha1/transformer/transformer.cue` | `#Transformer` (gains `requiredDirectives` / `optionalDirectives`) |
| `catalog/core/v1alpha1/module/module.cue` | `#Module` — `#policies` already supports this pattern |
| `catalog/opm_experiments/v1alpha1/` | Sandbox for experimental directives, traits, and transformers |
