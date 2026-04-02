# Design Package: `#Directive` Primitive — Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Directive` as a new primitive type within `#Policy`, alongside `#PolicyRule`. Directives describe operational behavior that the platform should execute on behalf of the module author — backup scheduling, pre-backup hooks, and restore procedures. Unlike `#PolicyRule`, directives carry no enforcement semantics (`mode`, `onViolation`).

The first well-known directive is `#BackupDirective`, a combined schema covering periodic backup, optional pre-backup hooks, and optional restore procedures. Transformers generate K8up resources from the directive. The OPM CLI reads directives to browse snapshots and execute restores.

This enhancement is a pragmatic stepping stone. Enhancement 006 proposed a comprehensive `#Claim` / `#Orchestration` system; this design extracts the module-level operational behavior concept as `#Directive` without introducing component-level claims, Blueprint composition changes, or a second rendering pipeline.

## Documents

1. [01-problem.md](01-problem.md) — Current backup duplication; component-level scope mismatch; restore gap; 006 complexity
2. [02-design.md](02-design.md) — `#Directive` primitive; `#Policy` changes; `#BackupDirective` schema; module integration
3. [03-transformer-integration.md](03-transformer-integration.md) — Directive matching on `#Transformer`; K8up output generation
4. [04-module-integration.md](04-module-integration.md) — Module author and release author experience; examples
5. [05-cli-integration.md](05-cli-integration.md) — `opm backup` commands: list, snapshots, restore
6. [06-decisions.md](06-decisions.md) — Decision log with rationale and alternatives

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/archive/004-backup-trait/` | Predecessor — component-level two-trait backup design (archived) |
| `catalog/enhancements/006-claim-primitive/` | Broader design — `#Claim` + `#Orchestration` (Draft, not superseded) |
| `catalog/enhancements/007-offer-primitive/` | Supply-side counterpart to 006 (Draft, not superseded) |
| `catalog/core/v1alpha1/primitives/policy_rule.cue` | `#PolicyRule` — pattern followed by `#Directive` (minus enforcement) |
| `catalog/core/v1alpha1/policy/policy.cue` | `#Policy` construct (to gain `#directives` field) |
| `catalog/core/v1alpha1/transformer/transformer.cue` | `#Transformer` (to gain directive matching fields) |
| `catalog/core/v1alpha1/module/module.cue` | `#Module` — `#policies` already supports this pattern |
