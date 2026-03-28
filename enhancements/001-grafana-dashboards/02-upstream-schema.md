# Grafana Foundation SDK JSON Schema Reference

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

## Summary

The Grafana Foundation SDK publishes official JSON Schema files for dashboards, panel types, and common types at (https://github.com/grafana/grafana-foundation-sdk). These are the upstream source for `cue import` and must be vendored into the catalog before any CUE schema work begins.

## Primary Source

Repository: https://github.com/grafana/grafana-foundation-sdk

Schema files live under the `jsonschema/` directory of the default branch. They are auto-generated from Grafana's internal CUE definitions via the Cog code-generation tool (https://github.com/grafana/cog), staying in sync with each Grafana release. This makes them the most reliable upstream source for `cue import` — they are not hand-maintained and do not drift from the actual Grafana data model.

## Schema Files to Import

### Core Schemas

| File | Size | Raw Download URL | Scope |
| ---- | ---- | ---------------- | ----- |
| `dashboard.jsonschema.json` | 64.4 KB | https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/dashboard.jsonschema.json | Full dashboard model (current, v0) |
| `common.jsonschema.json` | 44 KB | https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/common.jsonschema.json | Shared types referenced by dashboard |
| `dashboardv2beta1.jsonschema.json` | 83.8 KB | https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/dashboardv2beta1.jsonschema.json | Next-gen format (experimental, do not import now) |

Do not import `dashboardv2beta1.jsonschema.json`. It is experimental and the schema is subject to breaking changes. It will be imported in a future release when the v2 format stabilizes.

### Panel Schemas

All panel schemas are in the same `jsonschema/` directory. Import all of them.

| File | Panel Type |
| ---- | ---------- |
| `timeseries.jsonschema.json` | Time series line/area chart |
| `stat.jsonschema.json` | Single value stat |
| `gauge.jsonschema.json` | Radial/linear gauge |
| `table.jsonschema.json` | Tabular data |
| `barchart.jsonschema.json` | Bar chart |
| `piechart.jsonschema.json` | Pie/donut chart |
| `heatmap.jsonschema.json` | Heat map |
| `histogram.jsonschema.json` | Histogram |
| `logs.jsonschema.json` | Log viewer (Loki) |
| `text.jsonschema.json` | Markdown/HTML text panel |
| `canvas.jsonschema.json` | Canvas panel |
| `nodeGraph.jsonschema.json` | Node graph |
| `traces.jsonschema.json` | Trace viewer |
| `flamegraph.jsonschema.json` | Flame graph |
| `stateTimeline.jsonschema.json` | State timeline |
| `statusHistory.jsonschema.json` | Status history |
| `xyChart.jsonschema.json` | XY chart |
| `datagrid.jsonschema.json` | Data grid |

### Datasource Query Schemas

Datasource-specific query schemas are also available in the same directory (e.g., `prometheus.jsonschema.json`, `loki.jsonschema.json`). Import these when implementing query target validation. They are not required for the initial dashboard schema work.

## Vendoring Location

Place downloaded files under:

```
catalog/opm/v1alpha1/schemas/vendor/grafana/
├── IMPORT_NOTES.md
├── dashboard.jsonschema.json
├── common.jsonschema.json
└── panels/
    ├── timeseries.jsonschema.json
    ├── stat.jsonschema.json
    ├── gauge.jsonschema.json
    ├── table.jsonschema.json
    ├── barchart.jsonschema.json
    ├── piechart.jsonschema.json
    ├── heatmap.jsonschema.json
    ├── histogram.jsonschema.json
    ├── logs.jsonschema.json
    ├── text.jsonschema.json
    ├── canvas.jsonschema.json
    ├── nodeGraph.jsonschema.json
    ├── traces.jsonschema.json
    ├── flamegraph.jsonschema.json
    ├── stateTimeline.jsonschema.json
    ├── statusHistory.jsonschema.json
    ├── xyChart.jsonschema.json
    └── datagrid.jsonschema.json
```

`IMPORT_NOTES.md` records the exact `cue import` commands used, the Grafana release version the schemas were pulled from, and any post-import fixups applied. See `03-cue-import-strategy.md` for the commands and known fixup requirements.

Do not commit `dashboardv2beta1.jsonschema.json` to the vendor directory.

## Dashboard JSON Model — Key Structures

This section encodes the key Grafana dashboard JSON structures that the CUE schema must cover. An implementing agent must not need to reverse-engineer the upstream JSON Schema to understand these structures.

### Top-Level Fields

```json
{
  "uid": "string (8-40 chars, unique identifier)",
  "title": "string (required)",
  "description": "string (optional)",
  "tags": ["string"],
  "timezone": "browser | utc | IANA-TZ-ID",
  "time": { "from": "now-6h", "to": "now" },
  "refresh": "30s | 1m | false",
  "editable": true,
  "graphTooltip": 0,
  "schemaVersion": 42,
  "panels": [],
  "templating": { "list": [] },
  "annotations": { "list": [] },
  "links": []
}
```

Required for a valid Grafana dashboard: `schemaVersion` (currently 42) and `title`. All other top-level fields are optional. The `uid` must be unique within a Grafana instance; Grafana generates one if omitted, but OPM-managed dashboards must supply it explicitly to enable idempotent provisioning.

### GridPos (24-Column Grid)

```json
{
  "h": 8,
  "w": 12,
  "x": 0,
  "y": 0
}
```

| Field | Description |
| ----- | ----------- |
| `h` | Height in grid units |
| `w` | Width in grid units (max 24) |
| `x` | Column position, 0-indexed (0-23) |
| `y` | Row position, 0-indexed, unbounded |

The grid is 24 columns wide. Panels auto-flow downward when `y` values overlap. `x + w` must not exceed 24.

### DataSourceRef

```json
{
  "type": "prometheus",
  "uid": "datasource-uid-string"
}
```

Also valid as a template variable reference: `"${DS_PROMETHEUS}"`. The variable form is preferred in OPM-managed dashboards so the datasource UID is not hardcoded.

### FieldConfig

```json
{
  "defaults": {
    "color": { "mode": "thresholds | fixed | palette-classic" },
    "unit": "short | bytes | percent | s | ms | reqps",
    "decimals": 2,
    "thresholds": {
      "mode": "absolute | percentage",
      "steps": [
        { "color": "green", "value": null },
        { "color": "red", "value": 80 }
      ]
    },
    "mappings": [],
    "custom": {}
  },
  "overrides": []
}
```

`thresholds.steps[0].value` must be `null` to represent the base threshold. `overrides` is a list of field matcher + property override pairs; the schema for overrides is panel-type-specific and lives in the panel schema files.

### Panel Types — Key Four

**timeseries**

```json
{
  "type": "timeseries",
  "fieldConfig": {
    "defaults": {
      "custom": {
        "drawStyle": "line | bars | points",
        "fillOpacity": 10,
        "lineWidth": 2,
        "stacking": { "mode": "none | normal | percent" }
      }
    }
  },
  "options": {
    "legend": { "displayMode": "list | table | hidden", "placement": "bottom | right" },
    "tooltip": { "mode": "single | multi | none" }
  }
}
```

**stat**

```json
{
  "type": "stat",
  "options": {
    "colorMode": "none | value | background",
    "graphMode": "area | none",
    "textMode": "auto",
    "reduceOptions": {
      "values": false,
      "calcs": ["lastNotNull"]
    }
  }
}
```

**gauge**

```json
{
  "type": "gauge",
  "options": {
    "orientation": "auto | horizontal | vertical",
    "gaugeType": "gauge | donut",
    "showThresholdLabels": false
  }
}
```

**table**

```json
{
  "type": "table",
  "options": {
    "showHeader": true,
    "sortBy": [],
    "pagination": { "pageSize": 10 }
  }
}
```

### PromQL Target

```json
{
  "expr": "rate(http_requests_total[5m])",
  "refId": "A",
  "legendFormat": "{{method}} {{status}}",
  "format": "time_series | table | heatmap",
  "instant": false,
  "intervalFactor": 2
}
```

`refId` is required and must be unique within a panel's `targets` list. `legendFormat` supports Go template syntax referencing label names from the query result (https://grafana.com/docs/grafana/latest/panels-visualizations/query-transform-data/).

### Template Variable (query type)

```json
{
  "type": "query",
  "name": "namespace",
  "label": "Namespace",
  "hide": 0,
  "datasource": { "type": "prometheus", "uid": "uid" },
  "query": { "query": "label_values(kube_pod_info, namespace)" },
  "refresh": 1,
  "sort": 1,
  "multi": false,
  "includeAll": false
}
```

Supported variable types: `query`, `custom`, `constant`, `datasource`, `interval`, `textbox`. The `hide` field accepts `0` (visible), `1` (hide label), or `2` (hide entirely). `refresh` values: `0` = never, `1` = on dashboard load, `2` = on time range change.

## Freshness

| Schema | Status | Update Cadence |
| ------ | ------ | -------------- |
| `dashboard.jsonschema.json` | Current (v0) | Each Grafana release |
| Panel schemas | Current | Each Grafana release |
| `dashboardv2beta1.jsonschema.json` | Experimental | Ongoing, not yet stable |

Re-import all schemas on each major Grafana release. Minor releases may also add new panel options; re-import when panel schema changes are needed. The exact re-import procedure, including post-import fixups, is documented in `03-cue-import-strategy.md`.
