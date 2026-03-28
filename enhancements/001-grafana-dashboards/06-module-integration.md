# Module Integration

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

## Summary

Module authors add a `dashboard.cue` file to their module that uses `#DashboardResource` and the panel helpers from `opm/v1alpha1`. ConfigMap rendering is automatic — no manual wiring beyond composing the `#Dashboard` component.

## Module Author Workflow

1. Ensure the module depends on `opmodel.dev/opm/v1alpha1@v1` (the version that includes observability).
2. Create `modules/<name>/dashboard.cue`.
3. Import `obsv` (`opm/v1alpha1/resources/observability`) and `schemas` (`opm/v1alpha1/schemas`).
4. Define one or more dashboards under `spec.dashboards`.
5. Compose `obsv.#Dashboard` into the package (typically alongside `components.cue`).
6. Run `task -C modules check` to validate.
7. Run `task -C modules publish TYPE=patch` to publish.

## Minimal Example

```cue
// modules/myapp/dashboard.cue
package myapp

import (
    obsv    "opmodel.dev/opm/v1alpha1/resources/observability@v1"
    schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

// Compose the Dashboard component
obsv.#Dashboard

// Dashboard definitions
spec: dashboards: {
    "myapp-overview": schemas.#DashboardSchema & {
        title: "My App Overview"
        tags: ["myapp", "monitoring"]

        panels: {
            "request-rate": schemas.#TimeseriesPanel & {
                gridPos: {w: 12, h: 8, x: 0, y: 0}
                targets: [schemas.#PromQLTarget & {
                    expr:         "rate(http_requests_total{app=\"myapp\"}[5m])"
                    legendFormat: "{{method}} {{status}}"
                }]
            }
            "error-rate": schemas.#StatPanel & {
                gridPos: {w: 6, h: 4, x: 12, y: 0}
                targets: [schemas.#PromQLTarget & {
                    expr:  "rate(http_requests_total{app=\"myapp\",status=~\"5..\"}[5m])"
                    refId: "A"
                }]
                fieldConfig: defaults: {
                    unit: schemas.#Units.percent
                    thresholds: {
                        mode: "absolute"
                        steps: [
                            {color: "green", value: null},
                            {color: "red",   value: 0.05},
                        ]
                    }
                }
            }
        }
    }
}
```

In `modules/myapp/components.cue`, the ConfigMaps are generated automatically when `obsv.#Dashboard` is composed.

## Reusable Pattern Library

Location: `catalog/opm/v1alpha1/schemas/observability_patterns.cue`

### #ContainerMetricsRow

Pre-built set of panels for standard Kubernetes container metrics. Accepts a `selector` string for PromQL label matchers.

```cue
// Usage:
panels: schemas.#ContainerMetricsRow & {
    selector: "namespace=\"\(#config.namespace)\",pod=~\"\(#config.name)-.*\""
    rowY: 0  // vertical position of the row
}
```

Produces 4 panels:

- CPU usage timeseries (`rate(container_cpu_usage_seconds_total{<selector>}[5m])`)
- Memory usage timeseries (`container_memory_working_set_bytes{<selector>}`)
- Network received timeseries (`rate(container_network_receive_bytes_total{<selector>}[5m])`)
- Network transmitted timeseries (`rate(container_network_transmit_bytes_total{<selector>}[5m])`)

### #HttpRequestsRow

Pre-built panels for HTTP workloads. Accepts a `selector` and optional `latencyBuckets` for histogram-based latency.

```cue
// Usage:
panels: schemas.#HttpRequestsRow & {
    selector: "job=\"myapp\""
    rowY:     10
}
```

Produces 3 panels:

- Request rate timeseries
- Error rate stat panel (threshold: green < 1%, red > 5%)
- Latency percentiles timeseries (p50, p95, p99 from histogram)

### #Units

Common Grafana unit identifiers:

```cue
schemas.#Units: {
    bytes:        "bytes"
    bitsPerSec:   "bps"
    percent:      "percentunit"
    seconds:      "s"
    milliseconds: "ms"
    reqPerSec:    "reqps"
    short:        "short"
    none:         "none"
}
```

### #ThresholdPresets

```cue
schemas.#ThresholdPresets: {
    okWarnCrit: {
        mode: "absolute"
        steps: [
            {color: "green",  value: null},
            {color: "yellow", value: 80},
            {color: "red",    value: 90},
        ]
    }
    percentage: {
        mode: "percentage"
        steps: [
            {color: "green", value: null},
            {color: "red",   value: 80},
        ]
    }
}
```

## Jellyfin Proof-of-Concept

The initial implementation proof-of-concept is the Jellyfin media server module.

File: `modules/jellyfin/dashboard.cue`

```cue
package jellyfin

import (
    obsv    "opmodel.dev/opm/v1alpha1/resources/observability@v1"
    schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

obsv.#Dashboard

spec: dashboards: {
    "jellyfin-overview": schemas.#DashboardSchema & {
        title:       "Jellyfin Media Server"
        description: "Container metrics and Jellyfin application metrics"
        tags:        ["jellyfin", "media", "monitoring"]
        time: {from: "now-3h", to: "now"}

        variables: {
            namespace: schemas.#Variable & {
                type:  "query"
                label: "Namespace"
                datasource: {type: "prometheus"}
                query: "label_values(kube_pod_info{pod=~\"jellyfin.*\"}, namespace)"
            }
        }

        panels: {
            // Container metrics using reusable pattern
            schemas.#ContainerMetricsRow & {
                selector: "namespace=\"$namespace\",pod=~\"jellyfin.*\""
                rowY:     0
            }

            // Jellyfin-specific: active streams
            "active-streams": schemas.#StatPanel & {
                title:   "Active Streams"
                gridPos: {w: 6, h: 4, x: 0, y: 9}
                targets: [schemas.#PromQLTarget & {
                    // If Jellyfin exposes metrics via jellyfin-exporter or similar
                    expr:  "jellyfin_active_streams_total{namespace=\"$namespace\"}"
                    refId: "A"
                }]
                fieldConfig: defaults: unit: schemas.#Units.short
            }

            // Jellyfin-specific: transcoding sessions
            "transcoding-sessions": schemas.#StatPanel & {
                title:   "Transcoding Sessions"
                gridPos: {w: 6, h: 4, x: 6, y: 9}
                targets: [schemas.#PromQLTarget & {
                    expr:  "jellyfin_transcoding_sessions_total{namespace=\"$namespace\"}"
                    refId: "A"
                }]
                fieldConfig: defaults: {
                    unit: schemas.#Units.short
                    thresholds: schemas.#ThresholdPresets.okWarnCrit
                }
            }
        }
    }
}
```

**Wiring in `modules/jellyfin/components.cue`:** No additional wiring needed. Composing `obsv.#Dashboard` automatically routes the rendered dashboard JSON into `configMaps`. The ConfigMap `grafana-dashboard-jellyfin-overview` is created with the `grafana_dashboard: "1"` label.

## Validation Workflow

After adding a dashboard to a module:

```bash
# 1. Check CUE validity
task -C modules check

# 2. Inspect rendered ConfigMap (optional, for visual verification)
cue export ./modules/jellyfin/ -e 'components.configMaps["grafana-dashboard-jellyfin-overview"].data["jellyfin-overview.json"]'

# 3. Import JSON into Grafana for visual verification
# (paste the output into Grafana Dashboard Import)

# 4. Publish module with bumped version
task -C modules publish TYPE=patch
```

## Bundle-Level Dashboards

A Bundle can define cross-module dashboards that aggregate metrics from multiple bundle instances.

The following pattern is not implemented in the initial release. It is documented here for future reference.

```cue
// bundles/gamestack/dashboard.cue
package gamestack

import (
    obsv    "opmodel.dev/opm/v1alpha1/resources/observability@v1"
    schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

obsv.#Dashboard

spec: dashboards: {
    "gamestack-overview": schemas.#DashboardSchema & {
        title: "Game Stack Overview"
        panels: {
            // Aggregate across all MC server instances in the bundle
            "all-players": schemas.#StatPanel & {
                targets: [schemas.#PromQLTarget & {
                    expr: "sum(mc_players_online{namespace=\"$namespace\"})"
                }]
            }
        }
    }
}
```
