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
