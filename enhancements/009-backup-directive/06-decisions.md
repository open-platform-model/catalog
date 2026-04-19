# Design Decisions — `#Directive` Primitive: Backup & Restore

## Summary

Decision log for enhancement 009. The design evolved through several iterations:

1. **H1: Stretch `#PolicyRule`** — rejected: enforcement semantics incompatible with operations
2. **H2: `#Directive` in `#Policy`** — accepted: clean semantic separation
3. **Combined backup+restore directive** — initially accepted, then split
4. **Generic backup abstraction** — rejected: provider details leak; K8up and Velero are too different
5. **Provider-specific backup + provider-agnostic restore** — accepted: each directive serves one consumer

---

## Decisions

### D1: `#Directive` is a new primitive type, not a `#PolicyRule` variant

**Decision:** Introduce `#Directive` as a separate primitive type within `#Policy`, alongside `#PolicyRule`. Directives have no `enforcement` block.

**Alternatives considered:**
- Reuse `#PolicyRule` with optional enforcement — rejected: enforcement fields become meaningless noise; "policy rule" implies governance, not operations
- Add enforcement with a new mode value (e.g., "operational") — rejected: `onViolation` (block/warn/audit) has no meaning for backup scheduling

**Rationale:** Backup scheduling is not governance. The `enforcement.mode` and `enforcement.onViolation` fields are structurally incompatible with operational descriptions.

---

### D2: Module-level placement via `#Policy`, not component-level

**Decision:** Backup directives live in `#Policy` at the module level, targeting components via `appliesTo`.

**Alternatives considered:**
- Component-level placement (enhancement 004 trait approach) — rejected: backup is a module-level decision; component-level cannot express cross-component restore ordering
- Component-level with Blueprint composition (enhancement 006 claim approach) — rejected: overkill for backup; introduces second rendering pipeline

**Rationale:** Module authors think about backup as "protect this module's data." The policy model already supports module-level placement with component targeting.

---

### D3: Naming is `#Directive`

**Decision:** The primitive is named `#Directive`. Within `#Policy`, the field is `#directives`.

**Alternatives considered:**
- `#Orchestration` (from enhancement 006) — rejected: implies multi-step coordination; too heavy
- `#Procedure` — rejected: implies step-by-step execution; the schema describes *what*, not *how*
- `#Operation` — rejected: too generic; overloaded with Kubernetes "operator" terminology

**Rationale:** "Directive" communicates authoritative operational instruction without governance connotation. The pairing `#rules` (governance) and `#directives` (operations) reads naturally.

---

### D4: Two separate directives — backup (provider-specific) and restore (provider-agnostic)

**Decision:** Split into `#K8upBackupDirective` (consumed by transformer) and `#RestoreDirective` (consumed by CLI). Both self-contained with explicit duplication.

**Alternatives considered:**
- Single combined directive (original 009 design) — rejected: backup is inherently provider-specific (K8up has checkSchedule/pruneSchedule/Restic retention; Velero has TTL/CSI snapshots); combining forces either a leaky generic abstraction or K8up-specific fields in what should be a provider-agnostic contract
- Generic backup abstraction across providers — rejected after K8up/Velero API research: the two systems differ fundamentally in scope (namespace vs PVC), engine (Restic vs Kopia/CSI), hooks (PreBackupPod vs exec-in-container), retention (Restic prune vs TTL), and backend management (inline vs separate CR)

**Rationale:** Backup is provider-specific — different providers have different scheduling, retention, hook, and backend models. Restore is provider-agnostic — the CLI browses a Restic/Kopia repo regardless of who wrote to it. Separating means adding Velero support = new `#VeleroBackupDirective`, same `#RestoreDirective`.

---

### D5: Restore included from the start

**Decision:** `#RestoreDirective` is part of the initial design. The CLI reads it to automate restore procedures.

**Alternatives considered:**
- Defer restore (as 004 did) — rejected: restore is the primary motivation for CLI integration

**Rationale:** Turning a 12+ step manual `kubectl` procedure into `opm restore run` is the core value proposition.

---

### D6: Volume names reference component resources, not raw PVC names

**Decision:** `targets[component].volumes` map keys reference the component's `spec.volumes` entries. The transformer resolves volume name → PVC name.

**Alternatives considered:**
- Raw `pvcName` strings (004 approach) — rejected: no validated link; easy to typo
- Infer all PVCs from workload spec — rejected: not all PVCs should be backed up

**Rationale:** The directive targets a specific component via `appliesTo`. Referencing volumes by name creates a validated link.

---

### D7: `backend.s3` wrapper for future extensibility

**Decision:** S3 config is nested under `backend.s3` in the K8up directive and `repository.s3` in the restore directive.

**Alternatives considered:**
- Flat S3 fields at top level — rejected: no room for `gcs`, `azure` in future

**Rationale:** The wrapper allows adding alternative backends.

---

### D8: Enhancement 006 not superseded

**Decision:** Enhancement 006 stays as Draft. This enhancement does not supersede it.

**Rationale:** Enhancement 009 is a pragmatic stepping stone. 006's broader `#Claim`/`#Orchestration` design handles concerns (data dependencies, Blueprint composition) that this enhancement does not. The two are compatible.

---

### D9: Transformer matching via `requiredDirectives` field

**Decision:** `#Transformer` gains `requiredDirectives` and `optionalDirectives` fields.

**Alternatives considered:**
- Label-based matching only — rejected: labels carry no schema
- Separate directive rendering pipeline — rejected: unnecessary complexity

**Rationale:** Directive matching is a natural extension of existing multi-dimensional matching (labels, resources, traits).

---

### D10: PVC annotation is module author's responsibility (v1)

**Decision:** K8up's `k8up.io/backup=true` PVC annotation is managed by the module author or bypassed via K8up operator config.

**Rationale:** The transformer model does not support cross-component mutation.

---

### D11: Per-component target map, not flat target list

**Decision:** `targets` is a keyed map where each key is a component name.

**Alternatives considered:**
- Flat list of PVC targets — rejected: hooks are per-component, not global
- One policy per target — rejected: massive duplication of backend/schedule/retention

**Rationale:** Different components need different treatment (hooks, restore procedures). The per-component map groups all concerns per component.

---

### D12: Three resource types — volumes, configMaps, secrets

**Decision:** Backup targets can be volumes (Restic file backup), configMaps (API export), or secrets (API export).

**Alternatives considered:**
- Volumes only (004 approach) — rejected: ConfigMaps and Secrets also contain data worth protecting
- Discriminated union — rejected: keyed maps mirror component resource structure

**Rationale:** Each type has different backup mechanics. Map keys reference corresponding resource names on the component.

---

### D13: Field naming `backupPath` (not `mountPath` or `path`)

**Decision:** The subtree filter within a PVC is named `backupPath`, defaulting to `"/"`.

**Alternatives considered:**
- `mountPath` — rejected: sounds like a container mount point
- `path` — rejected: too generic
- `subPath` — rejected: Kubernetes has specific `subPath` semantics

**Rationale:** `backupPath` is unambiguous: "the path within the PVC to back up."

---

### D14: preBackupHook is per-component, not per-directive

**Decision:** `preBackupHook` lives inside each component's target entry in the K8up directive.

**Alternatives considered:**
- Global hook at directive level — rejected: different components need different hooks
- Hook per volume target — rejected: hooks are per-component, not per-volume

**Rationale:** A Jellyfin component needs SQLite checkpoint; a Postgres component needs pg_dump; static files need no hook.

---

### D15: Provider-specific backup, provider-agnostic restore

**Decision:** Backup directives are per-provider (`#K8upBackupDirective`). The restore directive (`#RestoreDirective`) is provider-agnostic and consumed by the CLI.

**Alternatives considered:**
- Both provider-agnostic — rejected after K8up/Velero API research: K8up (Restic retention, checkSchedule, pruneSchedule, PreBackupPod) and Velero (TTL, CSI snapshots, exec-in-container hooks, BackupStorageLocation) are too different to abstract cleanly
- Both provider-specific — rejected: restore is inherently provider-agnostic; the CLI browses a Restic repo regardless of who wrote to it

**Rationale:** Backup generates provider-specific CRs (transformer consumer). Restore reads a repository and orchestrates kubectl operations (CLI consumer). Different consumers, different abstraction levels.

---

### D16: Explicit duplication between backup and restore directives

**Decision:** Both directives carry their own backend/repository credentials and target lists. No structural references between them.

**Alternatives considered:**
- Restore references backup directive values — rejected: couples the two directives structurally; restore should work even if the backup directive changes
- Shared schema type for backend — rejected: the fields are named differently (`backend.s3` vs `repository.s3`) to reflect their different roles

**Rationale:** Each directive is self-contained. Module authors use `#config.backup` to deduplicate at the module level. Change the bucket → change `#config` → both directives update. The duplication is in the schema structure, not in the module code.

---

### D17: Restore directive gains `repository.format` field

**Decision:** `repository.format: *"restic" | "kopia"` tells the CLI which tool to use for repository access.

**Alternatives considered:**
- Auto-detect format from repository — rejected: adds complexity; Restic and Kopia repos may not be trivially distinguishable
- Assume Restic always — rejected: Velero defaults to Kopia (Restic deprecated in Velero 1.15+); future `#VeleroBackupDirective` will write Kopia repos

**Rationale:** K8up uses Restic. Velero uses Kopia. The CLI needs to know which tool to invoke. Default is `"restic"` since the first provider is K8up.

---

### D18: Restore order uses CUE definition order, not explicit ordering field

**Decision:** The `components` map in `#RestoreDirective` uses definition order as restore order. Database before app = write database first in the map.

**Alternatives considered:**
- Explicit `order: int` field — rejected: adds noise; CUE preserves struct field order; the visual order in the file matches the execution order
- Flat ordered list instead of map — rejected: maps are more natural for keyed data; component names as keys enable direct access

**Rationale:** CUE preserves struct field order. The module author writes components in the order they should be restored. Visual order = execution order — no indirection.

---

### D19: No default schedule in K8up backup directive

**Decision:** `schedule!: string` is required with no default. The module author must explicitly choose a backup schedule.

**Alternatives considered:**
- Default to `"0 2 * * *"` (2 AM daily) — rejected: backup frequency is a conscious decision; silent defaults risk either too-frequent backups (wasting resources) or insufficient coverage

**Rationale:** Unlike retention (where sensible defaults exist), schedule depends on the workload's data change rate and RPO requirements. The module or release author must make this choice.

---

## Revision 2026-04-19 — Unified directive + experimental sandbox

A second design pass followed a brainstorm that surfaced flaws in the D4/D11/D14/D16 shape: drift risk between the split directives, the `targets[]` typo trap, poor scope for per-component hooks, and no story for the CLI-vs-controller reconcile race during restore. D20–D25 below supersede the affected prior decisions. Original decisions remain in place so the evolution is traceable.

### Supersession summary

| Prior | Superseded by | Reason |
|---|---|---|
| D4: Two separate directives (backup + restore) | D20 | Split produced drift between parallel `repository`/`backend` blocks |
| D11: Per-component `targets` map | D21 | Reintroduced the string-key typo failure D6 claimed to fix |
| D12: Three resource types (volumes, configMaps, secrets) | D21 (partial) | ConfigMap/Secret backup drops from v1 scope |
| D14: `preBackupHook` per-component in directive | D22 | Hooks are component-scoped concerns, not policy-scoped |
| D16: Explicit duplication between directives | D20 | Moot after unification |

---

### D20: Single unified `#K8upBackupDirective` — backup + restore blocks

**Decision:** One directive with three sub-blocks:

- `schedule`, `checkSchedule`, `pruneSchedule`, `retention` — backup-only (K8up Schedule transformer).
- `repository` — shared; both consumers read it.
- `restore.<componentName>` — CLI-only; describes per-component restore procedure.

**Supersedes:** D4, D16.

**Rationale:** The prior split forced the module author to keep two parallel `repository` blocks in sync. The provider-specific-backup / provider-agnostic-restore insight from D15 is preserved: the directive remains K8up-specific overall, but the `restore` sub-block's shape is provider-agnostic and can be copied verbatim into a future `#VeleroBackupDirective`.

---

### D21: Drop `targets[]` — rely on `Policy.appliesTo`

**Decision:** The directive no longer enumerates PVCs, ConfigMaps, or Secrets per component. Backup scope is fully defined by `Policy.appliesTo`. K8up backs up PVCs belonging to the components named there.

**Supersedes:** D11, and D12 (partial — ConfigMap/Secret export drops from v1 scope).

**Rationale:** The `targets[componentName]` map reintroduced the exact failure mode D6 claimed to fix: a string-key typo silently omits a component. Since `appliesTo` already scopes the policy to components by CUE reference, duplicating that list in `targets` is redundant and unsafe.

**Open:** the concrete PVC annotation strategy (see 07-open-questions.md Q1).

---

### D22: `preBackupHook` lifted to `#PreBackupHookTrait`

**Decision:** Pre-backup hooks become a component trait, not a directive field. The PreBackupPod transformer consumes the trait. Hooks travel with the component.

**Supersedes:** D14.

**Rationale:** A SQLite checkpoint or `pg_dump` is a component property ("this workload needs quiescing before any backup"), not a backup-policy property. Trait scope means a component declares its quiescing procedure once, and any backup policy that targets it picks it up automatically.

---

### D23: Experimental directives live in `opm_experiments/v1alpha1`

**Decision:** `#K8upBackupDirective` and `#PreBackupHookTrait` ship in `opmodel.dev/opm_experiments/v1alpha1@v1`. Graduation to `opm/v1alpha1` is gated on 07-open-questions.md Q4.

**Rationale:** Sandboxes shape-iteration without locking the main `opm` catalog into unproven designs.

**Boundary:** the `#Directive` primitive itself — along with `#Policy.#directives` and `#Transformer.requiredDirectives` — remains in `core/v1alpha1`. Those are structural additions to the type system, not experiments on top of it. (Sequencing trade-off tracked in Q5.)

---

### D24: Lease-based pause for `opm restore run`

**Decision:** The CLI acquires a `coordination.k8s.io/v1` Lease per ModuleRelease during restore. The controller's reconciler checks the Lease and skips reconcile while it is held and unexpired.

**Scope:** per-ModuleRelease. Matches the controller's current whole-MR reconcile granularity. Per-component locking is a future optimization.

**Alternatives considered:**
- `spec.suspend: bool` on ModuleRelease (Flux pattern) — rejected: manual suspend flags get stuck on after a CLI crash; a Lease auto-expires.
- Suspend annotation — same failure mode as `spec.suspend`.

**Rationale:** Kubernetes-native, self-healing (expires if the CLI crashes), auditable via `kubectl get leases`. Same primitive `kube-controller-manager` uses for leader election.

**Open:** lease name, namespace, duration, renewal cadence, override mechanism (07-open-questions.md Q2).

---

### D25: CLI is the restore executor (v1)

**Decision:** Restore remains a CLI-driven, human-in-the-loop operation. The controller does not orchestrate restore in v1.

**Alternatives considered:**
- `RestoreJob` CRD owned by the controller — rejected for v1: adds a state machine and operator complexity for a rare, high-stakes operation where a human should stay in the loop.

**Rationale:** Restore is infrequent, irreversible, and benefits from explicit confirmation. Moving it to the controller is viable later if usage patterns change.

**Consequences:**
- CLI gains real cluster-mutation responsibility: Lease management, workload scale patching, Restic/Kopia invocation, S3 auth.
- The execution race with the controller is resolved via D24.
