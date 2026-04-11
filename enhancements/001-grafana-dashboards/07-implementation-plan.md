# Implementation Plan

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

## Summary

Five-phase implementation plan for adding Grafana dashboard support to OPM, covering schema import, opinionated wrappers, catalog registration, module proof-of-concept, and publishing.

## Prerequisites

Hard gates. Do not begin Phase 1 until all are satisfied.

- [ ] CUE v0.16.0 installed: `cue --version` reports v0.16.0+
- [ ] Workspace CUE version updated in all `cue.mod/module.cue` files: `language: { version: "v0.16.0" }`
- [ ] `task update-deps` run from workspace root after CUE upgrade
- [ ] `task -C catalog check` passes on current main branch (no pre-existing issues)

## Phase 1: Import and Vendor Upstream Schema

Goal: Download Grafana JSON Schema files, import into CUE, validate output.

### 1.1 Download schema files

```bash
BASE=catalog/opm/v1alpha1/schemas/vendor/grafana
mkdir -p "$BASE/panels"

curl -o "$BASE/dashboard.jsonschema.json" \
  https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/dashboard.jsonschema.json

curl -o "$BASE/common.jsonschema.json" \
  https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/common.jsonschema.json

# Download all panel schemas
for panel in timeseries stat gauge table barchart piechart heatmap histogram logs text canvas nodeGraph traces flamegraph stateTimeline statusHistory xyChart datagrid; do
  curl -o "$BASE/panels/${panel}.jsonschema.json" \
    "https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/${panel}.jsonschema.json"
done
```

### 1.2 Create and run import script

Create `catalog/opm/v1alpha1/schemas/vendor/grafana/import.sh` (see `03-cue-import-strategy.md` for content). Run it:

```bash
bash catalog/opm/v1alpha1/schemas/vendor/grafana/import.sh
```

### 1.3 Post-import cleanup

Apply all fixups described in the `03-cue-import-strategy.md` post-import checklist. Document every manual edit in `IMPORT_NOTES.md` alongside the generated files.

### 1.4 Validate against real dashboard JSON

```bash
# Get a sample Grafana dashboard JSON export and validate
cue vet sample-dashboard.json \
  ./catalog/opm/v1alpha1/schemas/vendor/grafana/dashboard_gen.cue
```

### Phase 1 verification

- `cue vet ./catalog/opm/v1alpha1/schemas/vendor/grafana/...` exits 0
- Sample dashboard JSON validates without errors
- `IMPORT_NOTES.md` documents all manual fixups

## Phase 2: Opinionated Wrappers (Layer 2)

Goal: Build the user-facing schema layer on top of imported types.

### 2.1 Create `catalog/opm/v1alpha1/schemas/observability.cue`

Define the following (full definitions in `04-architecture.md`):

- `#DashboardSchema`, `#GridPos`, `#DataSourceRef`, `#PromQLTarget`, `#GenericTarget`
- Panel helpers: `#TimeseriesPanel`, `#StatPanel`, `#GaugePanel`, `#TablePanel`, `#TextPanel`, `#LogsPanel`
- `#Variable`, `#Annotation`

### 2.2 Create `catalog/opm/v1alpha1/schemas/observability_render.cue`

Define the following (full specification in `05-catalog-integration.md`):

- `#RenderDashboard` function
- Panel ID auto-assignment
- GridPos auto-layout algorithm
- UID derivation
- `_rawOverrides` merge logic

### 2.3 Create `catalog/opm/v1alpha1/schemas/observability_patterns.cue`

Define the following (full definitions in `06-module-integration.md`):

- `#ContainerMetricsRow`, `#HttpRequestsRow`
- `#Units`, `#ThresholdPresets`

### Phase 2 verification

```bash
task -C catalog fmt
task -C catalog vet
task -C catalog test
```

## Phase 3: Catalog Integration (Layer 3)

Goal: Register the new resource type in the catalog.

### 3.1 Create `catalog/opm/v1alpha1/resources/observability/dashboard.cue`

Define the following (full definition in `05-catalog-integration.md`):

- `#DashboardResource`, `#DashboardDefaults`, `#Dashboard`

### 3.2 Update `catalog/opm/v1alpha1/INDEX.md`

- Add observability category and dashboard resource entry.
- Run `task -C catalog generate:index` if available.

### Phase 3 verification

```bash
task -C catalog check
```

Expected: all fmt, vet, and test targets pass.

## Phase 4: Module Integration (Jellyfin Proof-of-Concept)

Goal: Demonstrate the feature with a real module.

### 4.1 Update `modules/jellyfin/cue.mod/module.cue`

Bump `opm/v1alpha1` dependency version after Phase 5.1 publishes. Do NOT manually edit the version pin — run `task update-deps` from the workspace root.

### 4.2 Create `modules/jellyfin/dashboard.cue`

Full definition in `06-module-integration.md`.

### 4.3 Verify rendering

```bash
# Validate CUE
task -C modules check

# Inspect rendered JSON
cue export ./modules/jellyfin/ \
  -e 'components.configMaps["grafana-dashboard-jellyfin-overview"].data["jellyfin-overview.json"]'
```

### 4.4 Visual verification

Import the rendered JSON into a Grafana instance to verify visual correctness. Panels must display without errors in Grafana UI.

## Phase 5: Publishing

Goal: Publish updated catalog and modules; update all downstream consumers.

### 5.1 Publish `opm/v1alpha1` with major version bump

Adding a new resource category is a breaking change and requires a major version bump.

```bash
task -C catalog version:bump DOMAIN=opm TYPE=major
task -C catalog publish:smart
```

### 5.2 Update all workspace dependencies

```bash
# From workspace root
task update-deps
```

This updates `cli/examples`, `poc-controller`, `modules`, and `releases` to the new version.

### 5.3 Publish Jellyfin module

```bash
task -C modules publish TYPE=patch MODULE=jellyfin
```

### 5.4 Verify downstream consumers

```bash
task -C catalog check
task -C modules check
```

## Commit Strategy

One commit per phase. Follow Conventional Commits.

| Phase | Commit message                                                  |
| ----- | --------------------------------------------------------------- |
| 1     | `chore(opm/v1alpha1): vendor grafana json schema`               |
| 2     | `feat(opm/v1alpha1): add observability dashboard schemas`       |
| 3     | `feat(opm/v1alpha1): add DashboardResource to catalog`          |
| 4     | `feat(modules/jellyfin): add grafana dashboard`                 |
| 5     | `chore: publish opm/v1alpha1 major version and update deps`     |

## Rollback

If any phase fails:

1. Revert the phase's changes.
2. Run `task -C catalog check` to confirm clean state.
3. Address the issue before retrying.

Do not publish partial implementations. Each phase must pass its verification gate before the next begins.
