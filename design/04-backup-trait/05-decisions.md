# Design Decisions

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for all design choices made during the backup trait design.

---

## Decisions

| Decision | Chosen | Rationale | Alternative Considered |
| --- | --- | --- | --- |
| Pattern type | Trait (not Blueprint) | Backup is a cross-cutting, optional concern that enhances an existing component — same shape as Expose, WorkloadIdentity, HttpRoute. Blueprints are for defining workload types, not add-on behaviors. All 6 existing blueprints are workload types; all 22 existing traits are optional enhancements. | Blueprint — rejected: would be the first non-workload blueprint, breaking the conceptual model |
| Trait count | Two traits: `#BackupTrait` + `#PreBackupHookTrait` | Separates the scheduling/storage concern from the preparation concern. Many backups need no hook. Hooks require app-specific knowledge that the backup trait should not own. Follows the Expose/HttpRoute precedent of composable independent traits. | Single combined trait — rejected: forces every backup to define a hook field (even if empty) and conflates two independent concerns |
| Trait location | `catalog/opm/v1alpha1/traits/data/` | The backup contract is generic and provider-agnostic. It belongs in the core OPM catalog alongside other traits. The `data/` subcategory groups it with future data-related traits. | `catalog/k8up/v1alpha1/traits/` — rejected: couples the generic contract to a specific provider |
| `appliesTo` scope | Any component (unrestricted) | Backup may apply to workloads, data stores, ConfigMaps with associated PVCs, or other component types. Restricting to workloads-only would prevent valid use cases. | Restricted to StatefulWorkload/SimpleDatabase — rejected: too narrow, prevents backing up non-workload components |
| PVC targeting | Explicit `pvcName` field in the trait spec | Avoids coupling the backup trait to workload resource internals. Supports components that are not workloads. Clear and unambiguous. | Implicit PVC discovery from component spec — rejected: couples backup to workload schema, fails for non-workload components, ambiguous when multiple PVCs exist |
| Pre-backup hook model | Image + command + optional volume mount | Covers all known use cases: SQLite checkpoint (needs volume), RCON (network-only, no volume), pg_dump (needs volume), custom scripts. Simple contract, maximum flexibility. | Typed hook registry (#SqliteHook, #RconHook) — rejected: front-loads complexity, grows unboundedly, provides little benefit over a shell command |
| Hook volume mount | Optional, independent from backup PVC | The hook's volume may differ from the backup target (e.g., hook accesses a database PVC, backup captures a different data PVC). Keeping them independent avoids incorrect assumptions. | Auto-derive from backup.pvcName — rejected: not always the same PVC |
| S3 bucket scope | Per-trait-instance (no shared defaults) | Each application gets its own bucket. Environment-level defaults would reduce repetition but add a new inheritance mechanism. Self-contained config is simpler and explicit. | Environment-level S3 defaults with per-module overrides — deferred: adds complexity without critical benefit |
| Schema provider-agnosticism | Trait schema has no K8up/Restic-specific fields | Enables future provider swaps (Velero, etc.) without changing the trait contract or any module that uses it. K8up specifics live only in the transformer. | Include resticOptions in schema — rejected: leaks implementation into the contract |
| Backend structure | Nested under `backend.s3` wrapper | Allows adding `backend.gcs`, `backend.azure` in the future without breaking the schema | Flat S3 fields at top level — rejected: no room for other backends |
| Transformer count | Single transformer handles both traits | The backup transformer uses `requiredTraits` for `#BackupTrait` and `optionalTraits` for `#PreBackupHookTrait`. One transformer, conditional output. Simpler registration and fewer moving parts. | Two separate transformers — rejected: the PreBackupPod is meaningless without a Schedule; separating them adds coordination complexity |
| PVC annotation (`k8up.io/backup=true`) | Module author responsibility (v1) | Cross-component mutation (trait on component A modifying component B's output) is not supported by the transformer model. The K8up operator can be configured with `skipWithoutAnnotation: false` as an alternative. | Transformer emits PVC annotation — rejected: requires cross-component mutation not supported today |
| Restore support | Not in scope (v1) | Restores are infrequent, manual operations. A trait adds value for recurring automation (backups), not one-off recovery. K8up Restore CRs can be created manually. | `#RestoreTrait` — deferred: insufficient value for the complexity |
| Pod security context | Not in scope (v1) | Default K8up pod security context is sufficient for most cases. `fsGroup`/`runAsUser` configuration can be added to the schema in a future iteration. | Include in v1 schema — deferred: adds fields most users won't need initially |
| Backup browser pattern | Separate workload component (Hatch), not a trait | Traits enhance existing components — they do not create new workload components. A backup browser is an independent application with its own container, config, and network surface. Deploying it as a separate component makes it a conscious opt-in by the module author and avoids cross-component mutation. | `#BackupBrowserTrait` — rejected: traits cannot create new components; would require cross-component resource generation not supported by the transformer model |
| Backup browser implementation | Hatch (lightweight Go + HTMX web sidecar) | Hatch already provides authenticated file browsing, role-based access, SafeFS sandboxing, audit logging, and download support. Backup snapshot browsing is a natural extension of its file browsing domain. | Standalone backup-specific tool (e.g., Backrest) — rejected: introduces a separate application with its own auth model, duplicating capabilities Hatch already provides |
| Backup browser scope (v1) | Read-only: browse snapshots, list files, download | Restores are infrequent, high-risk operations better handled via manual K8up Restore CRs. Keeping the browser read-only simplifies the security model. | Include restore support — deferred: insufficient value for the complexity and risk |
| Config delivery to Hatch | ConfigMap mount or inline container argument (`--config`) | Supports both Kubernetes (ConfigMap) and non-Kubernetes deployments (inline YAML argument). Follows the Envoy Proxy pattern of flexible config injection. | ConfigMap only — rejected: limits deployment to Kubernetes; inline argument broadens platform support |
| Multi-repo aggregation | Not in scope (v1) | One Hatch instance browses one Restic repo. Per-component deployment is explicit and simple. Multi-repo aggregation adds discovery and routing complexity. | Multi-repo from v1 — deferred: adds complexity without critical need |
