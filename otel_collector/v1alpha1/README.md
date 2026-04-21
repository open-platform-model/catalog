# otel-collector OPM resources

## Summary

OPM resource + transformer definitions for the three custom resources shipped by the [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator):

- `OpenTelemetryCollector` (`opentelemetry.io/v1beta1`) — collector pipeline deployments
- `Instrumentation` (`opentelemetry.io/v1alpha1`) — auto-instrumentation sidecar injection
- `OpAMPBridge` (`opentelemetry.io/v1alpha1`) — OpAMP control-plane fleet management

Pure passthrough: transformers emit native CRs with OPM name prefix, namespace, and labels applied; `spec` is copied verbatim. Typed specs are vendored from upstream CRDs with `timoni mod vendor crd`.

This module does **not** deploy the operator itself. Install the controller + RBAC + CRDs separately (see `modules/otel_collector/` in this workspace). The operator requires cert-manager.

## Contents

| Path | Description |
|---|---|
| `resources/telemetry/collector.cue` | `#Collector` resource wrapper (OpenTelemetryCollector) |
| `resources/telemetry/instrumentation.cue` | `#Instrumentation` resource wrapper |
| `resources/telemetry/op_amp_bridge.cue` | `#OpAMPBridge` resource wrapper |
| `providers/kubernetes/` | `#Provider` + 3 passthrough transformers |
| `schemas/opentelemetry.io/*/*/types_gen.cue` | Timoni-generated types. Do not edit. |

## CRD Source

- **Upstream repo**: [open-telemetry/opentelemetry-operator](https://github.com/open-telemetry/opentelemetry-operator)
- **CRD files**: `config/crd/bases/opentelemetry.io_{opentelemetrycollectors,instrumentations,opampbridges}.yaml`
- **Raw URLs**:
  - `https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml`
  - `https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_instrumentations.yaml`
  - `https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_opampbridges.yaml`
- **CRD API group**: `opentelemetry.io`

Only `v1beta1` of `OpenTelemetryCollector` is exposed. The operator supports `v1alpha1` via a conversion webhook, but the storage version (and recommended authoring version) is `v1beta1`. `Instrumentation` and `OpAMPBridge` remain at `v1alpha1`.

## Regenerating schemas

```bash
# 1. Download CRDs
for crd in opentelemetrycollectors instrumentations opampbridges; do
  curl -sSL -o "/tmp/otel-${crd}.yaml" \
    "https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_${crd}.yaml"
done

# 2. Vendor each CRD
cd catalog/otel_collector/v1alpha1
for f in /tmp/otel-opentelemetrycollectors.yaml /tmp/otel-instrumentations.yaml /tmp/otel-opampbridges.yaml; do
  timoni mod vendor crd -f "$f"
done

# 3. Drop v1alpha1 OpenTelemetryCollector (only v1beta1 is exposed) and relocate
rm -rf cue.mod/gen/opentelemetry.io/opentelemetrycollector/v1alpha1
mv cue.mod/gen/opentelemetry.io schemas/
rmdir cue.mod/gen

# 4. Validate
cue vet ./...
cue vet -t test ./...
```

## Links

- [OpenTelemetry Operator documentation](https://opentelemetry.io/docs/platforms/kubernetes/operator/)
- [OpenTelemetryCollector API reference](https://github.com/open-telemetry/opentelemetry-operator/blob/main/docs/api.md)
- [Timoni mod vendor crd docs](https://timoni.sh/cue-schemas/)
