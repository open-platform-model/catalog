# Design Package: `#Directive` Primitive — Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Directive` as a new primitive type within `#Policy`, alongside `#PolicyRule`. Directives describe operational behavior that the platform should execute on behalf of the module author. Unlike `#PolicyRule`, directives carry no enforcement semantics (`mode`, `onViolation`).

Two well-known directives for backup and restore:

- **`#K8upBackupDirective`** — provider-specific. Consumed by the K8up transformer to generate K8up Schedule and PreBackupPod CRs. Unapologetically K8up-specific: Restic retention, checkSchedule, pruneSchedule.
- **`#RestoreDirective`** — provider-agnostic. Consumed by the OPM CLI to browse snapshots and execute restores. Carries its own repository connection info and per-component restore procedures with definition-ordered execution.

The two directives are self-contained with explicit duplication of backend/target info. Module authors use `#config` to deduplicate at the module level.

## Documents

1. [01-problem.md](01-problem.md) — Current backup duplication; component-level scope mismatch; restore gap; 006 complexity
2. [02-design.md](02-design.md) — `#Directive` primitive; `#Policy` changes; `#K8upBackupDirective` and `#RestoreDirective` schemas
3. [03-transformer-integration.md](03-transformer-integration.md) — K8up transformer matching and output generation
4. [04-module-integration.md](04-module-integration.md) — Module author and release author experience; examples
5. [05-cli-integration.md](05-cli-integration.md) — `opm backup/restore` commands using `#RestoreDirective`
6. [06-decisions.md](06-decisions.md) — Decision log with rationale and alternatives

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/archive/004-backup-trait/` | Predecessor — component-level two-trait backup design (archived) |
| `catalog/enhancements/006-claim-primitive/` | Broader design — `#Claim` + `#Orchestration` (Draft, not superseded) |
| `catalog/enhancements/007-offer-primitive/` | Supply-side counterpart to 006 (Draft, not superseded) |
| `catalog/core/v1alpha1/primitives/policy_rule.cue` | `#PolicyRule` — pattern followed by `#Directive` (minus enforcement) |
| `catalog/core/v1alpha1/policy/policy.cue` | `#Policy` construct (gains `#directives` field) |
| `catalog/core/v1alpha1/transformer/transformer.cue` | `#Transformer` (gains directive matching fields) |
| `catalog/core/v1alpha1/module/module.cue` | `#Module` — `#policies` already supports this pattern |
