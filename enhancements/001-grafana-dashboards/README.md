# Design Package: Grafana Dashboards

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

## Summary

This design package documents how OPM modules can define and publish Grafana dashboards alongside their applications using CUE. Dashboards are defined as a new `#DashboardResource` inside `opm/v1alpha1`, backed by an upstream Grafana JSON Schema imported via `cue import`. The feature enables composable, type-safe dashboard definitions that render to Kubernetes ConfigMaps for Grafana sidecar provisioning.

## Prerequisites

Implementation requires CUE v0.16.0 or later. Do not begin implementation until `cue --version` reports v0.16.0 or later.

CUE v0.15.0 (current workspace version at time of authoring) has known issues with `oneOf/anyOf/allOf` schema combinators. The Grafana dashboard JSON Schema uses these combinators extensively. CUE v0.16.0 introduces the `matchN` primitive, which handles these combinators correctly. Running `cue import` on the Grafana schema under v0.15.0 will produce import errors on complex schema combinators.

## Reading Order

Read all documents below before implementing. Order is significant.

1. [01-landscape.md](01-landscape.md) — CUE + Grafana ecosystem survey; prior art; why building native OPM support
2. [02-upstream-schema.md](02-upstream-schema.md) — Grafana Foundation SDK JSON Schema; download URLs; key dashboard structures
3. [03-cue-import-strategy.md](03-cue-import-strategy.md) — `cue import` command syntax; output format; known limitations; post-import cleanup
4. [04-architecture.md](04-architecture.md) — Three-layer schema design; CUE unification guarantees; escape hatch
5. [05-catalog-integration.md](05-catalog-integration.md) — `#DashboardResource` definition; `#RenderDashboard` logic; ConfigMap rendering
6. [06-module-integration.md](06-module-integration.md) — Module author guide; reusable patterns; Jellyfin proof-of-concept
7. [07-implementation-plan.md](07-implementation-plan.md) — Phased execution plan; verification commands; version strategy
8. [08-decisions.md](08-decisions.md) — All architectural decisions with rationale and source citations

## Agent Instructions

Follow these steps in order. Do not skip or reorder.

1. Verify CUE version: `cue --version` must report v0.16.0 or later. Stop if it does not.
2. Read `catalog/AGENTS.md` and `catalog/CONSTITUTION.md`.
3. Read `catalog/docs/STYLE.md`.
4. Read all design documents listed in Reading Order above.
5. Read `DESIGN_PATTERNS.md` at the workspace root.
6. Follow the phased plan in [07-implementation-plan.md](07-implementation-plan.md) exactly.
7. Run `task -C catalog check` (fmt + vet + test) after each phase before proceeding.
8. Run `task -C modules check` after Phase 4.
9. Commit with message: `feat(opm/v1alpha1): add observability dashboard resource`

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/CONSTITUTION.md` | 9 core design principles governing all catalog changes |
| `catalog/docs/design-principles.md` | Expanded principle explanations with examples |
| `catalog/docs/STYLE.md` | Documentation and CUE style conventions |
| `DESIGN_PATTERNS.md` | Reusable CUE patterns used throughout the catalog |
| `catalog/opm/v1alpha1/` | Target directory for new schema files |
