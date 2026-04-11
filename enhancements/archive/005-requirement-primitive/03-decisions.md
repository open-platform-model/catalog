# Design Decisions — Requirements Primitive & Backup/Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Summary

Decision log for all architectural and design choices made during the requirements primitive and backup/restore enhancement. Each decision is numbered sequentially and recorded as it is made. Decisions are append-only.

This log merges decisions from the original [004-backup-trait](../004-backup-trait/) enhancement with decisions from this enhancement. Decisions D28-D33 represent the convergence on `#Requirement` as a new primitive, superseding earlier approach-exploration decisions (D1, D4).

---

## Foundational Decisions

### D1: Pattern type is Trait (not Blueprint) — SUPERSEDED by D28

**Decision:** Backup is a cross-cutting, optional concern that enhances an existing component — same shape as Expose, WorkloadIdentity, HttpRoute. Blueprints are for defining workload types, not add-on behaviors.

**Alternatives considered:**
- Blueprint — rejected: would be the first non-workload blueprint, breaking the conceptual model. All 6 existing blueprints are workload types; all 22 existing traits are optional enhancements.

**Rationale:** Backup enhances a component without changing its fundamental nature. This is the trait pattern.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D2: Backup and restore are separate declarations

**Decision:** Backup and restore are modeled as separate primitives, not a single combined declaration.

**Alternatives considered:**
- Single `#DataProtectionPolicy` combining backup and restore — simpler surface, but conflates two distinct operational workflows
- Restore as a section within the backup declaration — conceptually tidy, but restore has its own lifecycle (triggered manually, not scheduled)

**Rationale:** Backup is an automated, scheduled operation. Restore is a manual, operator-triggered operation with distinct scenarios (in-place vs DR). They have different audiences (backup runs unattended; restore requires human judgment). This follows the same reasoning as splitting `#BackupTrait` and `#PreBackupHookTrait` — separate concerns with separate lifecycles.

**Source:** Design discussion 2026-03-28; precedent from 004-backup-trait.

---

### D3: Restore is a first-class concern, not a documentation exercise

**Decision:** Restore must be declaratively encoded in the module definition and executable by the CLI, not left to manual documentation or operator knowledge.

**Alternatives considered:**
- Continue writing `DISASTER_RECOVERY.md` per module — not machine-readable, drifts from reality, not executable by CLI
- Rely on K8up's built-in restore CRs applied manually — requires operator to know PVC names, secret names, scaling behavior, OPM label requirements

**Rationale:** Testing on kind-opm-dev (2026-03-28) demonstrated that full DR requires 12+ manual steps with hidden requirements (OPM management labels, secret labeling for auto-created secrets). A module-declared contract eliminates this knowledge gap.

**Source:** User decision 2026-03-28; validated by kind-opm-dev backup/restore test battery.

---

### D4: Three design approaches documented; primitive type decision deferred — SUPERSEDED by D28

**Decision:** The enhancement documents Approach A (pure PolicyRule), Approach B (Trait + PolicyRule hybrid), and Approach C (pure Trait). The choice of which approach to implement — and whether to expand `#PolicyRule`, create a new primitive, or accept trait semantics for contracts — is deferred.

**Alternatives considered:**
- Commit to one approach now — premature without resolving the primitive taxonomy question
- Document a fourth approach (new `#Contract` primitive) in full — better explored as a separate catalog-level discussion since it affects all future primitives

**Rationale:** All approaches produce the same CLI behavior and module author experience. The difference is where the contract lives in the primitive taxonomy. This is an architectural question that deserves focused discussion.

**Source:** Design discussion 2026-03-28.

---

## Backup Design Decisions

### D5: Trait location in core OPM catalog

**Decision:** Backup traits/policies live in `catalog/opm/v1alpha1/traits/data/` (or `policies/data/`), not in the K8up catalog.

**Alternatives considered:**
- `catalog/k8up/v1alpha1/traits/` — rejected: couples the generic contract to a specific provider

**Rationale:** The backup contract is provider-agnostic. It belongs in the core OPM catalog. The `data/` subcategory groups it with future data-related primitives.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D6: `appliesTo` scope is unrestricted (any component)

**Decision:** The backup primitive applies to any component type — workloads, data stores, ConfigMaps with associated PVCs, or other component types.

**Alternatives considered:**
- Restricted to StatefulWorkload/SimpleDatabase — rejected: too narrow, prevents backing up non-workload components

**Rationale:** Backup may apply to any component that has persistent data.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D7: Explicit PVC targeting

**Decision:** In Approach C, the trait requires an explicit `pvcName` field. In Approaches A and B, volume references use component-level names (`volume: "config"`) resolved at render time via inventory.

**Alternatives considered:**
- Implicit PVC discovery from component spec — rejected: couples backup to workload schema, fails for non-workload components, ambiguous when multiple PVCs exist

**Rationale:** Explicit targeting avoids coupling and ambiguity. The two styles (concrete PVC name vs component-level volume name) reflect different levels of abstraction; approaches A/B are more portable, approach C is simpler.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait D5 (PVC targeting) and 005 D5 (volume references).

---

### D8: Pre-backup hook model is image + command + optional volume mount

**Decision:** Hooks are specified as an image, command array, and optional volume mount. This covers all known use cases: SQLite checkpoint (needs volume), RCON (network-only), pg_dump (needs volume), custom scripts.

**Alternatives considered:**
- Typed hook registry (#SqliteHook, #RconHook) — rejected: front-loads complexity, grows unboundedly, provides little benefit over a shell command

**Rationale:** Simple contract, maximum flexibility. Multi-step preparation is expressed as a shell script within the command array.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D9: Hook as separate trait (Approach C) vs inline field (Approaches A/B)

**Decision:** In Approach C, the pre-backup hook is a separate `#PreBackupHookTrait`. In Approaches A and B, the hook is an optional inline field within the backup schema.

**Alternatives considered:**
- Always separate trait — rejected for A/B: adds unnecessary primitive count when the hook is logically part of the backup contract
- Always inline — rejected for C: forces every backup to carry hook schema fields even when unused

**Rationale:** The Approach C split follows the Expose/HttpRoute precedent of composable independent traits. The A/B inline approach is simpler when the hook is part of a broader policy declaration.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait D2.

---

### D10: Hook volume mount is independent from backup PVC

**Decision:** The hook's volume mount may differ from the backup target PVC. They are configured independently.

**Alternatives considered:**
- Auto-derive hook volume from backup PVC name — rejected: not always the same PVC (e.g., hook accesses database PVC, backup captures a different data PVC)

**Rationale:** Keeping them independent avoids incorrect assumptions.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D11: S3 bucket scope is per-instance (no shared defaults)

**Decision:** Each backup instance has its own S3 backend config. No environment-level defaults.

**Alternatives considered:**
- Environment-level S3 defaults with per-module overrides — deferred: adds a new inheritance mechanism without critical benefit

**Rationale:** Self-contained config is simpler and explicit. Each application gets its own bucket.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D12: Provider-agnostic schema; K8up is an implementation detail

**Decision:** The backup/restore schemas contain no K8up/Restic-specific fields. K8up specifics live only in the transformer.

**Alternatives considered:**
- Include resticOptions in schema — rejected: leaks implementation into the contract
- Fully abstract backend (no S3 fields) — rejected: too abstract; S3 is the dominant backup storage pattern used by K8up, Velero, Restic, and Rclone alike

**Rationale:** Enables future provider swaps without changing the contract or any module that uses it. S3 fields are a pragmatic compromise.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait and 005 D9.

---

### D13: Backend structure uses nested `backend.s3` wrapper

**Decision:** S3 config is nested under `backend.s3`.

**Alternatives considered:**
- Flat S3 fields at top level — rejected: no room for other backends

**Rationale:** Allows adding `backend.gcs`, `backend.azure` in the future without breaking the schema.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D14: Single transformer handles both backup and hook

**Decision:** One transformer uses `requiredTraits` for backup and `optionalTraits` for hook. Conditional output based on hook presence.

**Alternatives considered:**
- Two separate transformers — rejected: the PreBackupPod is meaningless without a Schedule; separating them adds coordination complexity

**Rationale:** Simpler registration and fewer moving parts.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D15: PVC annotation is module author responsibility (v1)

**Decision:** The `k8up.io/backup=true` annotation on the PVC is not emitted by the transformer. Module authors add it, or K8up is configured with `skipWithoutAnnotation: false`.

**Alternatives considered:**
- Transformer emits PVC annotation — rejected: requires cross-component mutation not supported by the transformer model today

**Rationale:** Cross-component mutation (trait on component A modifying component B's output) introduces complexity not justified for v1.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

## Restore Design Decisions

### D16: RestorePolicy is parameterized by scenario

**Decision:** The restore declaration defines behavior for two distinct scenarios: `inPlace` (workload exists) and `disasterRecovery` (namespace gone). The CLI selects the scenario via `--scenario` flag.

**Alternatives considered:**
- Single restore path that always does the maximal procedure — wasteful for simple rollbacks
- Automatic scenario detection by the CLI — adds implicit magic and may guess wrong

**Rationale:** In-place restore and DR have fundamentally different prerequisites. The operator knows which scenario they are in; the declaration tells the CLI how to execute each.

**Source:** User decision 2026-03-28; derived from kind-opm-dev DR testing.

---

### D17: Health check is required in the restore declaration

**Decision:** The restore declaration must include a `healthCheck` (HTTP path and port) that the CLI uses to verify restore success.

**Alternatives considered:**
- Optional health check — the CLI just scales up and reports success without verification
- Reuse the component's liveness/readiness probes — these are provider-specific (K8s concept) and may not be accessible from the declaration level

**Rationale:** Restore without verification is incomplete. DR testing confirmed that checking `/health` after restore was the critical step that proved data integrity.

**Source:** User decision 2026-03-28; "To help me see that it actually restored correctly I have created a Jellyfin user that I will be expecting to be preserved."

---

### D18: Volume references use component-level names in Approaches A/B

**Decision:** The `targets` field references volumes by their component-level name (e.g., `"config"`), not by the rendered K8s PVC name.

**Alternatives considered:**
- K8s PVC names directly — couples the declaration to K8s and to the specific release's naming conventions
- No explicit target; back up everything — too broad, backs up ephemeral volumes unnecessarily

**Rationale:** Module authors should not need to know how OPM names PVCs at render time. The CLI/transformer resolves component-level volume names to concrete PVC names using the inventory. Follows Principle V (Portability by Design).

**Source:** Design discussion 2026-03-28.

---

### D19: DR prerequisites (OPM management labels) are encoded in the declaration

**Decision:** The `disasterRecovery` section includes a `managedByOPM` flag that tells the CLI to add `app.kubernetes.io/managed-by: open-platform-model` labels when creating PVCs and secrets during DR.

**Alternatives considered:**
- Always add the label — simpler, but hides the "why"
- Require operators to remember the label — the exact problem being solved
- Add a `--adopt` flag to `opm release apply` instead — addresses symptom, not cause

**Rationale:** During DR testing, `opm release apply` failed because manually-created PVCs lacked the OPM management label. Encoding this in the declaration ensures the CLI knows to add labels automatically.

**Source:** User observation 2026-03-28; discovered during kind-opm-dev DR testing.

---

### D20: CLI is the first executor; controller support comes later

**Decision:** `opm release restore` is implemented in the CLI first. The poc-controller gains restore orchestration in a follow-up enhancement.

**Alternatives considered:**
- Controller-first — more operationally robust, but the controller is still a proof of concept
- Both simultaneously — too much scope for one enhancement

**Rationale:** The CLI is the primary deployment tool today. Operators need restore now. The controller can adopt the same contracts later since both read the same CUE declarations.

**Source:** User decision 2026-03-28; "The second part must be built into the CLI today (and the poc-controller tomorrow)."

---

## Scope Decisions

### D21: Restore support deferred in Approach C

**Decision:** Approach C (pure trait) explicitly defers restore. Restores remain manual via K8up Restore CRs.

**Alternatives considered:**
- `#RestoreTrait` in Approach C — would converge with Approach B

**Rationale:** A trait adds value for recurring automation (backups), not one-off recovery. If restore support is needed, Approach B or A is more appropriate.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D22: Pod security context deferred (v1)

**Decision:** Pod security context configuration for backup/restore pods is not in scope for v1.

**Alternatives considered:**
- Include in v1 schema — adds fields most users will not need initially

**Rationale:** Default K8up pod security context is sufficient for most cases. `fsGroup`/`runAsUser` can be added in a future iteration.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

## Browser and UI Decisions

### D23: Backup browser is a separate workload component (Hatch), not a trait

**Decision:** The backup browser is deployed as an independent workload component, not as a trait on the backed-up component.

**Alternatives considered:**
- `#BackupBrowserTrait` — rejected: traits cannot create new components; would require cross-component resource generation not supported by the transformer model

**Rationale:** Traits enhance existing components — they do not create new workload components. A backup browser is a distinct application with its own container, config, and network surface. Deploying it as a separate component makes it a conscious opt-in.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D24: Hatch is the recommended backup browser implementation

**Decision:** Hatch (lightweight Go + HTMX web sidecar) is the recommended browser.

**Alternatives considered:**
- Standalone backup-specific tool (e.g., Backrest) — rejected: introduces a separate application with its own auth model, duplicating capabilities Hatch already provides

**Rationale:** Hatch already provides authenticated file browsing, role-based access, SafeFS sandboxing, audit logging, and download support. Backup snapshot browsing is a natural extension.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D25: Backup browser scope is read-only in v1

**Decision:** v1 supports browse snapshots, list files, download. No restore support in the browser.

**Alternatives considered:**
- Include restore support — deferred: insufficient value for the complexity and risk

**Rationale:** Restores are infrequent, high-risk operations better handled via CLI `opm release restore` or manual K8up Restore CRs. Keeping the browser read-only simplifies the security model.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D26: Config delivery to Hatch is flexible (ConfigMap or inline argument)

**Decision:** Hatch config can be delivered as a ConfigMap mount or inline container argument (`--config`).

**Alternatives considered:**
- ConfigMap only — rejected: limits deployment to Kubernetes; inline argument broadens platform support

**Rationale:** Follows the Envoy Proxy pattern of flexible config injection.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

### D27: Multi-repo aggregation deferred (v1)

**Decision:** One Hatch instance browses one Restic repo. Multi-repo aggregation is a future feature.

**Alternatives considered:**
- Multi-repo from v1 — deferred: adds discovery and routing complexity without critical need

**Rationale:** Per-component deployment is explicit and simple.

**Source:** Design discussion 2026-03-28; prior art from 004-backup-trait.

---

## Primitive Taxonomy Decisions

### D28: New primitive `#Requirement` for operational contracts (supersedes D1, D4)

**Decision:** Introduce `#Requirement` as a new first-class OPM primitive for module-author-declared operational contracts. Backup and restore are modeled as `#BackupRequirement` and `#RestoreRequirement`. This supersedes D1 (trait pattern) and D4 (deferred primitive decision).

**Alternatives considered:**
- Approach A: Pure PolicyRule (04-approach-a-pure-policy.md) — rejected: PolicyRules flow platform -> module (governance mandates). Backup/restore flows module -> platform (operational needs). Using PolicyRule inverts the ownership model.
- Approach B: Hybrid Trait + PolicyRule (05-approach-b-hybrid.md) — rejected: conflates two distinct concerns into existing primitives that don't quite fit. Traits are behavioral preferences, not operational contracts. Adding a compliance PolicyRule adds ceremony most teams don't need.
- Approach C: Pure Trait (06-approach-c-pure-trait.md) — rejected: traits configure the component itself. Backup/restore asks the platform to act *on behalf of* the component. Also, traits have no restore story.
- Expand PolicyRule to support contracts — rejected: PolicyRule's `enforcement` field is governance-oriented. Adding contract semantics dilutes its meaning.

**Rationale:** The current taxonomy has four primitives but no category for "what the module needs from the platform." This is a genuine gap, not a matter of finding the right existing primitive. Requirements are distinct from traits (inward behavior), policies (outward governance), and interfaces (bidirectional data contracts). Future requirements beyond backup/restore (DNS, certificates, database provisioning, storage provisioning, shared networking) validate that this is a general-purpose category, not a one-off.

**Source:** User decision 2026-03-29; design discussion exploring all three approaches.

---

### D29: `#RequirementGroup` construct mirrors `#Policy` pattern

**Decision:** Requirements are grouped by a `#RequirementGroup` construct that targets components via `appliesTo`, mirroring how `#Policy` groups `#PolicyRule` instances. The `#RequirementGroup` lives at the module level in a `#requirements` map field.

**Alternatives considered:**
- Component-level embedding (like traits) — rejected: requirements are *about* the component, not *part of* the component's spec. Module-level placement allows targeting multiple components and enables per-component variation within a single module.
- Flat list of requirements on module — rejected: map-based keying enables named requirement groups with different `appliesTo` targets.

**Rationale:** The `#Policy` pattern (group + appliesTo + spec composition) is proven and well-understood. Reusing the same structural pattern for requirements reduces cognitive load — module authors learn one targeting mechanism. The map key provides meaningful names for documentation and CLI output.

**Source:** User decision 2026-03-29; inspired by `catalog/core/v1alpha1/policy/policy.cue`.

---

### D30: Requirements live at module level, not component level

**Decision:** `#requirements` is a field on `#Module`, not on `#Component`. Each `#RequirementGroup` uses `appliesTo` to target specific components.

**Alternatives considered:**
- Component-level `#requirements` field — rejected: backup/restore span the module's operational boundary, not individual component behavior. Module-level placement enables one requirement group to target multiple components.
- Both module-level and component-level — rejected: two places to declare requirements creates ambiguity about precedence and merging.

**Rationale:** Requirements describe what the module needs from the platform, which is a module-level concern. A single backup requirement group can target the one component that has persistent data, while a shared network requirement can target multiple components. This also aligns with the planned move of `#Interface` (provides/requires) from component level to module level.

**Source:** User decision 2026-03-29.

---

### D31: Policy stays platform -> module; module authors do not write PolicyRules

**Decision:** `#PolicyRule` and `#Policy` remain the platform team's governance primitives. Module authors use `#Requirement` for their needs. `#Policy` will move from `#Module` to a future `#PlatformModule` construct in a separate enhancement.

**Alternatives considered:**
- Allow module authors to write policies — rejected: conflates governance (platform mandates) with operational needs (module declarations). The directional clarity (policy = platform -> module, requirement = module -> platform) is a key design property.

**Rationale:** Clean ownership boundaries are a core OPM principle (Principle II: Separation of Concerns). Platform teams mandate. Module authors declare. These are different relationships with different trust models.

**Source:** User decision 2026-03-29.

---

### D32: `#Requirement` has no enforcement field

**Decision:** A requirement is inherently required. There is no `enforcement` field. If the platform cannot fulfill a requirement, the runtime (CLI) prints a warning that the requirement is not enabled/provided.

**Alternatives considered:**
- `fulfillment: "required" | "optional"` field — rejected: adds complexity for a distinction that can be expressed by simply not declaring the requirement
- `enforcement` field like PolicyRule — rejected: enforcement is a governance concept. Requirements are contracts, not rules.

**Rationale:** A requirement is a statement of need. The platform either fulfills it or doesn't. There is no "warn" vs "block" distinction — if backup isn't provided, the module runs without backup and the CLI warns. This is simpler and more honest than pretending the platform can enforce a module's needs.

**Source:** User decision 2026-03-29.

---

### D33: `#SharedNetwork` migrates from PolicyRule to Requirement

**Decision:** `#SharedNetwork` is reclassified as a `#SharedNetworkRequirement`. It is a module-author declaration ("my components need shared networking"), not a platform governance rule.

**Alternatives considered:**
- Keep as PolicyRule — rejected: the module author writes it, not the platform team. Using PolicyRule misrepresents ownership.
- Model via Interface (RFC-0004 provides/requires) — deferred: interfaces model data flow between components, not operational needs. SharedNetwork may eventually be expressed as interface wiring, but the requirement model is simpler for v1.

**Rationale:** SharedNetwork fails the PolicyRule ownership test: it is written by the module author and expresses a need, not a mandate. As a requirement, it correctly signals "my components need this from the platform."

**Source:** User decision 2026-03-29.
