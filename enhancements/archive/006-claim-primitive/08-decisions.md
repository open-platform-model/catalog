# Design Decisions — `#Claim` Primitive & Policy Broadening

## Summary

Decision log for all design choices. This enhancement went through three design iterations before converging:

1. **005-requirement-primitive**: `#Requirement` as module-level primitive with `appliesTo` (superseded)
2. **006 v1 (requires-construct)**: `#Requires` construct with `#Interface` + `#Requirement` at module level (superseded)
3. **006 v2 (claim-primitive)**: `#Claim` as component-level primitive, Blueprint-composable; `#Policy` broadened with `#Rule` + `#Orchestration` (current)

The evolution from module-level to component-level was driven by the realization that new primitives must participate in Blueprint composition to avoid creating second-class citizens in the type system.

---

## Decisions

### D1: `#Claim` is a component-level primitive, Blueprint-composable

**Decision:** Claims live at component level alongside Resources and Traits. They contribute a named field to `spec` and compose into Blueprints via `composedClaims`.

**Alternatives considered:**
- Module-level with `appliesTo` (005 design, 006 v1 design) — rejected: module-level primitives cannot participate in Blueprints, creating second-class citizens. A `#BackedUpStatefulWorkload` Blueprint that includes backup is a real pattern.
- Module-level with manual wiring (006 v1 `#Interface`) — rejected: same Blueprint composability problem.

**Rationale:** If Blueprints are OPM's core composition mechanism, every primitive must be composable in Blueprints. Component-level placement is the only way to achieve this.

**Source:** User decision 2026-03-29; identified Blueprint antipattern in module-level design.

---

### D2: Naming is `#Claim` with future counterpart `#Offer`

**Decision:** The primitive is named `#Claim`. The future counterpart (enhancement 007) is `#Offer`.

**Alternatives considered:**
- `#Requirement` / `#Capability` — viable but more verbose (`composedRequirements` vs `composedClaims`)
- `#Need` / `#Provide` — too informal
- `#Interface` / (various) — overloaded term, doesn't communicate "platform fulfills"

**Rationale:** "Claim" communicates the right relationship: the module declares a need, the platform binds it. K8s precedent (PersistentVolumeClaim). Short, pairs naturally with "Offer." `composedClaims` reads well in Blueprint definitions.

**Source:** User decision 2026-03-29.

---

### D3: The litmus test is "who controls the implementation?"

**Decision:** Resource/Trait = module author controls. Claim = platform fulfills. This is the boundary between primitives.

**Alternatives considered:**
- Boundary based on "the thing itself" (volume vs database) — rejected: blurs because the same thing can be both (a volume is a Resource the author controls; storage provisioning is a Claim the platform fulfills)

**Rationale:** The ownership distinction is clean and testable. "Does the module author specify the implementation, or just declare the need?" If the former, it's a Resource/Trait. If the latter, it's a Claim.

**Source:** Design discussion 2026-03-29.

---

### D4: `#Policy` broadened to contain `#Rule` and `#Orchestration`

**Decision:** `#Policy` serves two audiences: platform teams (via `#Rule`, replacing `#PolicyRule`) and module authors (via `#Orchestration`). Both use `appliesTo` to target components.

**Alternatives considered:**
- Separate `#Requires` construct for module-author cross-component concerns (006 v1) — rejected: introduces a new construct when `#Policy` already has `appliesTo` and module-level placement
- Keep Policy governance-only, add a separate `#Coordination` construct — rejected: unnecessary construct proliferation

**Rationale:** Policy already has the right structure: module-level, targets components, composes primitives. Broadening it to serve module authors for cross-component concerns is a natural extension. The split into `#Rule` (enforcement semantics) and `#Orchestration` (no enforcement) maintains clear ownership.

**Source:** User decision 2026-03-29.

---

### D5: Claims have two flavors: data (with `#shape`) and operational (without)

**Decision:** A `#Claim` may optionally have `#shape` — typed fields the author wires into component specs. Data claims (Postgres, Redis) have shapes. Operational claims (backup) do not.

**Alternatives considered:**
- Two separate primitive types (Interface + Requirement) — rejected: both are "what the component needs from the platform." The difference is whether the module author consumes typed fields, not a fundamental type distinction.
- All claims must have shapes — rejected: backup doesn't expose data to the component

**Rationale:** One primitive with optional shape is simpler than two primitives. The transformer/resolver handles the distinction at render time. From the component's perspective, both are spec fields.

**Source:** Design discussion 2026-03-29.

---

### D6: `#Offer` deferred to enhancement 007

**Decision:** The companion primitive to `#Claim` is deferred. Cross-module matching (Claim fulfilled by Offer) is also deferred.

**Rationale:** `#Claim` is independently useful with platform fulfillment (external binding). Adding `#Offer` later enables cross-module matching without changing the `#Claim` design.

**Source:** User decision 2026-03-29.

---

### D7: CUE late-binding needs spike before implementation

**Decision:** The mechanism for injecting concrete values into claim `#shape` fields at deploy time needs a spike/PoC.

**Rationale:** CUE's evaluation model may have constraints that affect the approach. The design is stable regardless of mechanism.

**Source:** RFC-0004 open questions; carried forward.

---

### D8: Well-known claims start with 6 core types in v1

**Decision:** v1 ships: `#PostgresClaim`, `#RedisClaim`, `#MysqlClaim`, `#S3Claim`, `#HttpServerClaim`, `#GrpcServerClaim`.

**Source:** Design discussion 2026-03-29; RFC-0004 v1 scope.

---

### D9: Claims and traits are independent rendering paths

**Decision:** Claim resolution/transformation and trait transformation are independent pipelines. A `#BackupClaim` does not implicitly create trait resources. Both can coexist on the same component.

**Source:** RFC-0004 path independence; user confirmation 2026-03-29.

---

### D10: `#RestoreOrchestration` lives in Policy, not as a component Claim

**Decision:** Restore is a cross-component orchestration procedure read by the CLI. It lives in `#Policy` as an `#Orchestration`, not as a component-level `#Claim`.

**Alternatives considered:**
- Component-level `#RestoreClaim` — rejected: restore is not a single-component concern. It orchestrates across components (restore DB first, then app) and the CLI reads it for `opm release restore`. This is inherently module-level.

**Rationale:** The rule of thumb: single-component needs are Claims. Cross-component coordination is Orchestration in Policy. Restore involves ordering, health verification, and DR procedures that span the module.

**Source:** Design discussion 2026-03-29.

---

### D11: `#SharedNetwork` migrates from PolicyRule to Orchestration

**Decision:** `#SharedNetwork` becomes `#SharedNetworkOrchestration` in Policy. It is a module-author declaration, not platform governance.

**Rationale:** The module author writes it. It expresses a need across components. It fits `#Orchestration` semantics.

**Source:** Carried from 005 D33; confirmed 2026-03-29.

---

### D12: `#Rule` replaces `#PolicyRule` with unchanged semantics

**Decision:** `#PolicyRule` is renamed to `#Rule` within the broadened `#Policy` construct. Semantics (enforcement mode, onViolation) are unchanged.

**Rationale:** Shorter name. Sits alongside `#Orchestration` in `#Policy`. The `Policy` construct name already provides the "policy" context.

**Source:** Design discussion 2026-03-29.

---

### D13: `#Orchestration` has no enforcement field

**Decision:** Orchestrations are declarations, not mandates. If the platform cannot fulfill an orchestration, the CLI warns. No `enforcement` block.

**Rationale:** Carried from 005 D32. Orchestrations express coordination needs. The platform fulfills or doesn't.

**Source:** User decision 2026-03-29.

---

## Prior Art: Design Iteration History

| Iteration | Enhancement | Key idea | Why superseded |
|-----------|------------|----------|----------------|
| 1 | 005 | `#Requirement` at module level with `appliesTo` | Blueprint can't compose module-level primitives |
| 2 | 006 v1 | `#Requires` construct with `#Interface` + `#Requirement` | Same Blueprint problem; two primitives when one suffices |
| 3 | 006 v2 | `#Claim` at component level + broadened `#Policy` | Current design |

Approach exploration documents (PolicyRule, Hybrid, pure Trait) are preserved in `005-requirement-primitive/` as reference material.
