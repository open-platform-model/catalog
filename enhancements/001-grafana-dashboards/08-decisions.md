# Architectural Decisions — Grafana Dashboards

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

---

## Summary

Decision log for all architectural choices made during the Grafana dashboard feature design.

---

## Decisions

### D1: Schema Location — Inside opm/v1alpha1

**Decision:** Dashboard schemas are added to the existing `opm/v1alpha1` catalog module as a new `observability` category, not as a separate independent domain module (e.g., `grafana/v1alpha1` or `cert_manager/v1alpha1`).

**Alternatives considered:**

- Separate domain module `grafana/v1alpha1` with independent versioning

**Rationale:** Tighter coupling is acceptable here because dashboards are deeply integrated with the OPM resource type system (`prim.#Resource`, `component.#Component`). Independent versioning would add complexity without benefit for this use case.

**Source:** User decision 2026-03-25; catalog module hierarchy in `catalog/CONSTITUTION.md`

---

### D2: Abstraction Level — Layered with Escape Hatch

**Decision:** Three-layer schema architecture: (1) imported Grafana JSON Schema as ground truth, (2) opinionated CUE wrappers with defaults, (3) `_rawOverrides` escape hatch for unsupported fields.

**Alternatives considered:**

- Low-level faithful mapping: CUE mirrors Grafana JSON exactly, no defaults
- High-level only: abstract types that hide all Grafana internals

**Rationale:** Grafana has 70+ panel types and extensive plugin-specific options. Modeling all of them with typed helpers is infeasible. The layered approach provides 80% of use cases with typed helpers while the escape hatch handles the rest. The imported base schema (Layer 1) ensures the escape hatch output is still validated.

**Source:** User decision 2026-03-25; Grafana Foundation SDK schema inventory at https://github.com/grafana/grafana-foundation-sdk/tree/main/jsonschema

---

### D3: Module Integration — Separate Resource Type

**Decision:** Dashboards are integrated as a `#DashboardResource` resource type that module authors explicitly compose (like `#ContainerResource`). Not a generic component field or standalone artifact.

**Alternatives considered:**

- Component field: add `dashboards?` field to all components
- Standalone artifact: separate dashboard files outside the component system

**Rationale:** Follows existing catalog patterns (`#ContainerResource`, `#CRDsResource`). Module authors opt in explicitly; no implicit coupling. The resource type system provides FQN, discoverability, and composition via `component.#Component`.

**Source:** User decision 2026-03-25; pattern from `catalog/opm/v1alpha1/resources/workload/container.cue`

---

### D4: Primary Datasource — Prometheus/PromQL

**Decision:** `#PromQLTarget` provides typed Prometheus query support. All other datasources use `#GenericTarget` (open struct).

**Alternatives considered:**

- Datasource-agnostic: all queries use open struct
- Multi-datasource: typed helpers for Prometheus, Loki, Elasticsearch

**Rationale:** Prometheus is the dominant metrics backend for Kubernetes workloads. Loki and others can be added in future iterations. Starting with one typed datasource produces better validation coverage for the most common case.

**Source:** User decision 2026-03-25

---

### D5: Upstream Schema Source — Foundation SDK JSON Schema

**Decision:** Import Grafana dashboard schemas from `grafana-foundation-sdk/jsonschema/` using `cue import`. Do not depend on Grafana's internal CUE files directly.

**Alternatives considered:**

- Import Grafana's `kinds/dashboard/dashboard_kind.cue` directly as a CUE dependency
- Hand-write all CUE types from the JSON model documentation

**Rationale:** Foundation SDK JSON Schema is auto-generated from Grafana's CUE via Cog, stays in sync with releases, is the most reliable published artifact, and is directly importable by `cue import`. Importing Grafana's CUE files directly would add an unstable external CUE module dependency. Hand-writing types risks drift from the real schema.

**Source:** https://github.com/grafana/grafana-foundation-sdk/tree/main/jsonschema

---

### D6: Import Scope — All 70+ Panel Schemas

**Decision:** Import `dashboard.jsonschema.json`, `common.jsonschema.json`, and all panel-specific schemas (timeseries, stat, gauge, table, etc.).

**Alternatives considered:**

- Import only dashboard + 4 main panel types initially
- Import only `dashboard.jsonschema.json` which references panels inline

**Rationale:** User decision for comprehensive coverage. Per-panel schemas provide tighter validation for each panel type. Minor additional effort at import time; significant improvement in type safety.

**Source:** User decision 2026-03-25

---

### D7: Schema Update Cadence — Major Grafana Releases

**Decision:** Re-import upstream JSON Schema on major Grafana releases.

**Alternatives considered:**

- Re-import on every Grafana release (too frequent)
- Re-import on demand only (risk of falling behind)
- Automated CI import (future option)

**Rationale:** Major releases introduce breaking schema changes. Minor and patch releases typically only add fields, which are backward-compatible in CUE's open struct model. Manual re-import with review (git diff) ensures unexpected changes are caught.

**Source:** User decision 2026-03-25

---

### D8: Version Bump — Major for New Resource Category

**Decision:** Adding the `observability` resource category to `opm/v1alpha1` requires a major version bump.

**Alternatives considered:**

- Minor bump (new additive feature)
- Patch bump (no breaking change)

**Rationale:** A new resource category introduces new imports in the `opm/v1alpha1` module. Downstream consumers must explicitly update. A major version bump makes this breaking change visible.

**Source:** User decision 2026-03-25; SemVer 2.0.0 in `catalog/CONSTITUTION.md`

---

### D9: Proof-of-Concept Module — Jellyfin Only

**Decision:** The initial proof-of-concept adds a dashboard to the Jellyfin module only.

**Alternatives considered:**

- Multiple modules (Jellyfin + Wolf + others)
- No proof-of-concept (implement schema only)

**Rationale:** A single module is sufficient to validate the end-to-end flow. Jellyfin is a simpler module (single container, standard metrics) that minimizes noise during initial integration. Wolf adds GPU-specific metrics complexity that is better addressed after the core pattern is proven.

**Source:** User decision 2026-03-25

---

### D10: Alert Rules — Future Follow-Up

**Decision:** Prometheus alert rule definitions are explicitly out of scope for this design.

**Rationale:** Alert rules have different schema, lifecycle, and deployment concerns (PrometheusRule CRD vs. ConfigMap provisioning). Adding them to this design would increase scope significantly. The `observability` category can accommodate alert rules in a follow-up design.

**Source:** User decision 2026-03-25

---

### D11: CUE Version Requirement — v0.16.0

**Decision:** Implementation requires CUE v0.16.0 or later.

**Rationale:** CUE v0.15.0 has known issues with `oneOf/anyOf/allOf` schema combinators. The Grafana dashboard JSON Schema uses these extensively for panel type discrimination and flexible field types. CUE v0.16.0 introduces `matchN`, which resolves these import issues cleanly.

**Source:** CUE changelog https://cuelang.org/docs/; research findings 2026-03-25

---

### D12: Dashboard UID Derivation — SHA-Based from FQN

**Decision:** When `uid` is not set explicitly, derive it as the first 40 characters of SHA-256(`"<module_fqn>:<dashboard_name>"`).

**Alternatives considered:**

- Require explicit UID always
- Use sequential integers
- Use random UUID at render time

**Rationale:** Deterministic UIDs allow dashboards to be updated in-place in Grafana (same UID = update, different UID = new dashboard). FQN + name ensures uniqueness across all OPM modules. Truncating to 40 characters stays within Grafana's 40-character UID limit.

**Source:** Grafana dashboard schema `uid` field constraint (max 40 chars)

---

### D13: Default Panel Height — Configurable Per-Dashboard

**Decision:** `#DashboardSchema` exposes `defaultPanelHeight: uint & >0 | *8`. Auto-layout uses this when `gridPos.y` is not specified.

**Alternatives considered:**

- Fixed default height (always 8)
- No auto-layout (require explicit `gridPos` on every panel)

**Rationale:** Most dashboards use a consistent panel height. Making it configurable per-dashboard reduces repetition. Explicit `gridPos` always overrides for panels that need a different height.

**Source:** User decision 2026-03-25

---

### D14: ConfigMap Rendering — Kubernetes Sidecar Pattern

**Decision:** Dashboards render as Kubernetes ConfigMaps with label `grafana_dashboard: "1"` for Grafana sidecar discovery.

**Alternatives considered:**

- Grafana API provisioning (POST /api/dashboards/db)
- Grafana Git Sync (Grafana 12 experimental feature)
- Custom CRD with controller

**Rationale:** ConfigMap sidecar is the most widely deployed pattern for Kubernetes-native Grafana dashboard provisioning. No custom controller required. Works with the standard Grafana Helm chart. Dashboards are version-controlled as CUE, not as JSON in Git.

**Source:** https://grafana.com/docs/grafana/latest/administration/provisioning/

---

### D15: No Runtime Dependency on Foundation SDK or Cog

**Decision:** OPM schemas are self-contained. No dependency on Grafana Foundation SDK packages or Cog at runtime.

**Rationale:** The Foundation SDK's JSON Schema files are used only at import time (to generate CUE types). The resulting CUE types are self-contained in `opm/v1alpha1`. Module authors do not need any Grafana-specific tooling to define dashboards — only the CUE CLI.

**Source:** Design principle; consistent with OPM's self-describing distribution principle in `catalog/CONSTITUTION.md`
