# Design Package: Requirements Primitive & Backup/Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Superseded by [006-requires-construct](../../006-requires-construct/) |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Requirement` as a new first-class OPM primitive for module-author-declared operational contracts. Requirements express "what this module needs from the platform" — a category missing from the current primitive taxonomy (Resource, Trait, Blueprint, PolicyRule). The `#RequirementGroup` construct groups requirements and targets them to components via `appliesTo`, mirroring how `#Policy` groups `#PolicyRule` instances.

Backup and restore are the first requirements defined using this primitive. The CLI gains `opm release restore` to orchestrate recovery using the module's declared restore requirement.

This enhancement supersedes [004-backup-trait](../004-backup-trait/) by incorporating its backup design and extending scope to include restore and the `#Requirement` primitive.

## Documents

1. [01-problem.md](01-problem.md) — Missing primitive category; backup duplication; restore is manual; DR requires hidden knowledge
2. [02-design.md](02-design.md) — `#Requirement` primitive and `#RequirementGroup` construct; backup, restore, and shared network as motivating use cases
3. [03-decisions.md](03-decisions.md) — All design decisions with rationale and alternatives considered
4. [10-cli-integration.md](10-cli-integration.md) — CLI commands: `opm release restore`, `opm release backup`, `opm release snapshots`

## Reference: Prior Approach Exploration

Before converging on `#Requirement`, three alternative approaches were explored for modeling backup/restore. These are preserved as reference material for the design decisions in 03-decisions.md:

- [04-approach-a-pure-policy.md](04-approach-a-pure-policy.md) — Using `#PolicyRule` for backup and restore contracts
- [05-approach-b-hybrid.md](05-approach-b-hybrid.md) — Traits for contracts, PolicyRules for enforcement
- [06-approach-c-pure-trait.md](06-approach-c-pure-trait.md) — Pure `#BackupTrait` and `#PreBackupHookTrait`

## Reference: Supporting Design Documents

These documents from the original 004-backup-trait design remain relevant for implementation:

- [07-transformer.md](07-transformer.md) — Kubernetes transformer: K8up Schedule and PreBackupPod generation
- [08-module-integration.md](08-module-integration.md) — How modules consume backup primitives; migration path
- [09-backup-browser.md](09-backup-browser.md) — Hatch integration for backup snapshot browsing

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/CONSTITUTION.md` | Core design principles governing all catalog changes |
| `catalog/docs/design-principles.md` | The eight OPM principles, especially Principle II (Separation of Concerns) |
| `catalog/docs/core/primitives.md` | Primitive taxonomy: Resource, Trait, Blueprint, PolicyRule |
| `catalog/docs/core/constructs.md` | Construct taxonomy: Component, Module, Policy, Provider |
| `catalog/core/v1alpha1/primitives/policy_rule.cue` | Existing `#PolicyRule` primitive — governance direction (platform → module) |
| `catalog/core/v1alpha1/policy/policy.cue` | Existing `#Policy` construct — `appliesTo` pattern reused by `#RequirementGroup` |
| `catalog/core/v1alpha1/module/module.cue` | `#Module` definition — `#requirements` field will be added here |
| `cli/docs/rfc/0004-interface-architecture.md` | RFC for `#Interface` (provides/requires) — related but distinct primitive |
| `catalog/enhancements/004-backup-trait/` | Predecessor enhancement (superseded by this one) |
| `modules/jellyfin/DISASTER_RECOVERY.md` | Manual DR procedure validated on kind-opm-dev (2026-03-28) |
| `modules/seerr/DISASTER_RECOVERY.md` | Manual DR procedure validated on kind-opm-dev (2026-03-28) |
