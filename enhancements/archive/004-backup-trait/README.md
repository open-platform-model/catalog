# Design Package: Backup Trait

| Field       | Value             |
| ----------- | ----------------- |
| **Status**  | Superseded by 005 |
| **Created** | 2026-03-28        |
| **Authors** | OPM Contributors  |

## Documents

1. [01-problem.md](01-problem.md) — Current backup integration; duplication across modules; maintenance cost
2. [02-design.md](02-design.md) — Two-trait approach: `#BackupTrait` and `#PreBackupHookTrait`; schema design; composition
3. [03-transformer.md](03-transformer.md) — Custom Kubernetes transformer; K8up resource generation; hook handling
4. [04-module-integration.md](04-module-integration.md) — How modules consume the traits; release-level configuration pattern
5. [05-decisions.md](05-decisions.md) — All design decisions with rationale and alternatives considered
6. [06-backup-browser.md](06-backup-browser.md) — Hatch integration; backup browsing UI; deployment modes

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/CONSTITUTION.md` | Core design principles governing all catalog changes |
| `catalog/opm/v1alpha1/traits/` | Existing trait definitions and patterns |
| `catalog/opm/v1alpha1/providers/kubernetes/transformers/` | Existing transformer patterns |
| `catalog/k8up/v1alpha1/` | K8up catalog schemas, resources, and transformers |
| `modules/jellyfin/` | Current backup implementation (reference) |
| `modules/seerr/` | Current backup implementation (reference) |
| `hatch/` | Recommended backup browser implementation |
| `hatch/docs/adr/011-backup-browsing.md` | Hatch ADR for backup browsing feature |
