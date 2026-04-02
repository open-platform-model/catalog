# Design Decisions — `#Directive` Primitive: Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for enhancement 009. The design evolved from exploring three approaches:

1. **H1: Stretch `#PolicyRule`** — reuse `#PolicyRule` with optional enforcement for operational concerns
2. **H2: `#Directive` in `#Policy`** — new primitive type alongside `#PolicyRule`, no enforcement semantics
3. **H3: Hybrid traits + policy** — keep component-level traits (004) and add module-level policy for restore only

H2 was selected for clean semantic separation between governance and operations.

---

## Decisions

### D1: `#Directive` is a new primitive type, not a `#PolicyRule` variant

**Decision:** Introduce `#Directive` as a separate primitive type within `#Policy`, alongside `#PolicyRule`. Directives have no `enforcement` block.

**Alternatives considered:**
- Reuse `#PolicyRule` with optional enforcement — rejected: enforcement fields become meaningless noise on backup directives; "policy rule" implies governance, not operations; conflates two distinct ownership models
- Add enforcement with a new mode value (e.g., "operational") — rejected: `onViolation` (block/warn/audit) has no meaning for backup scheduling

**Rationale:** Backup scheduling is not governance. There is no "violation" when a backup runs. The `enforcement.mode` and `enforcement.onViolation` fields are structurally incompatible with operational descriptions. A separate primitive type maintains clear semantics.

---

### D2: Module-level placement via `#Policy`, not component-level

**Decision:** Backup directives live in `#Policy` at the module level, targeting components via `appliesTo`. They do not attach to individual components.

**Alternatives considered:**
- Component-level placement (enhancement 004 trait approach) — rejected: backup is a module-level decision; component-level cannot express cross-component restore ordering or module-wide backup policy
- Component-level with Blueprint composition (enhancement 006 claim approach) — rejected: overkill for backup; `#BackedUpStatefulWorkload` Blueprint is theoretical, not demonstrated; introduces second rendering pipeline

**Rationale:** Module authors think about backup as "protect this module's data." The policy model already supports module-level placement with component targeting via `appliesTo`. No new constructs needed.

---

### D3: Naming is `#Directive`

**Decision:** The primitive is named `#Directive`. Within `#Policy`, the field is `#directives`.

**Alternatives considered:**
- `#Orchestration` (from enhancement 006) — rejected: implies multi-step coordination; too heavy for simple backup scheduling
- `#Procedure` — rejected: implies step-by-step execution; the schema describes *what*, not *how*
- `#Operation` — rejected: too generic; overloaded with Kubernetes "operator" terminology

**Rationale:** "Directive" communicates the right relationship: the module author directs the platform to perform operational behavior. It is declarative, authoritative without being enforcement. The pairing `#rules` (governance) and `#directives` (operations) within `#Policy` reads naturally.

---

### D4: Combined `#BackupDirective` (backup + hook + restore), not three separate directives

**Decision:** One directive with optional `preBackupHook` and `restore` sections, rather than `#BackupDirective` + `#PreBackupHookDirective` + `#RestoreDirective`.

**Alternatives considered:**
- Three separate directives (mirrors 004's two-trait split) — rejected: at the policy level there is no independent composition pressure; the module author always writes these together; splitting duplicates backend config and target lists

**Rationale:** Enhancement 004 split backup and pre-backup hook into two traits because traits compose independently on components. Directives live in `#Policy` where independent composition is not a requirement. Combining reduces boilerplate and keeps related config co-located. Optional fields (`preBackupHook?`, `restore?`) handle the cases where hooks or restore aren't needed.

---

### D5: Restore included from the start

**Decision:** `#BackupDirective` includes an optional `restore` block. The CLI reads it to automate restore procedures.

**Alternatives considered:**
- Defer restore to a follow-up enhancement (as 004 did) — rejected: restore is the primary motivation for CLI integration; without it, the CLI only lists snapshots, which is insufficient value

**Rationale:** The restore procedure (scale down, restore PVC, verify health) is described declaratively in the directive. The CLI executes it. This is the core value proposition — turning a 12+ step manual procedure into a single command. Deferring it would leave the enhancement incomplete.

---

### D6: Explicit `pvcName` in targets, not inferred from workload

**Decision:** The `targets` list uses explicit `pvcName` fields. PVCs are not inferred from the component's workload spec.

**Alternatives considered:**
- Infer PVC from workload volumes — rejected: couples backup to workload internals; fails for non-workload components; ambiguous when multiple PVCs exist

**Rationale:** Same decision as 004-D5. The module author knows which PVCs contain data worth protecting. Explicit naming is unambiguous and supports components with multiple PVCs or non-standard volume configurations.

---

### D7: `backend.s3` wrapper for future extensibility

**Decision:** S3 config is nested under `backend.s3`, not at the top level.

**Alternatives considered:**
- Flat S3 fields at top level — rejected: no room for `backend.gcs`, `backend.azure` in future versions

**Rationale:** Same decision as 004-D10. The wrapper allows adding alternative backends without breaking the schema.

---

### D8: Enhancement 006 not superseded

**Decision:** Enhancement 006 stays as Draft. This enhancement does not supersede it.

**Alternatives considered:**
- Supersede 006 with this enhancement — rejected: 006 addresses broader concerns (data claims, Blueprint composition, cross-component coordination) that this enhancement does not
- Supersede only the backup-specific parts of 006 — rejected: 006's backup claim and restore orchestration are part of a cohesive design; partial supersession creates confusion

**Rationale:** Enhancement 009 is a pragmatic stepping stone. It extracts one concept (`#Directive`) from 006's broader vision. If 006 is implemented later, `#BackupDirective` could either remain alongside `#Claim` or migrate to a `#BackupClaim` + restore orchestration. The two designs are compatible, not competing.

---

### D9: Transformer matching via `requiredDirectives` field

**Decision:** `#Transformer` gains `requiredDirectives` and `optionalDirectives` fields. The pipeline resolves directive matching by checking policies targeting the current component.

**Alternatives considered:**
- Label-based matching only (directive adds a label to the policy/component) — rejected: labels carry no schema; transformer needs access to directive spec values
- Separate directive rendering pipeline (enhancement 006 approach) — rejected: unnecessary complexity; extending the existing pipeline is sufficient

**Rationale:** Directive matching is a natural extension of the existing multi-dimensional matching (labels, resources, traits). The pipeline already resolves policy → component targeting via `appliesTo`. Adding directive FQN matching is a small incremental change.

---

### D10: PVC annotation is module author's responsibility (v1)

**Decision:** K8up's `k8up.io/backup=true` PVC annotation is added by the module author or bypassed via K8up operator config. The transformer does not modify other components' PVC definitions.

**Alternatives considered:**
- Transformer emits PVC annotation — rejected: requires cross-component mutation not supported by the transformer model

**Rationale:** Same decision as 004-D12. The transformer model produces output resources, it does not modify existing resources from other transformers. This is a deliberate architectural constraint.
