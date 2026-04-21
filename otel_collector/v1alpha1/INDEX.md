# v1alpha1 — Definition Index

CUE module: `opmodel.dev/otel_collector/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- telemetry/
+-- schemas/
    +-- opentelemetry.io/
        +-- instrumentation/
        |   +-- v1alpha1/
        +-- opampbridge/
        |   +-- v1alpha1/
        +-- opentelemetrycollector/
            +-- v1beta1/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | OtelCollectorKubernetesProvider transforms OpenTelemetry operator components to Kubernetes native resources (opentelemetry |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#CollectorTransformer` | `providers/kubernetes/transformers/collector_transformer.cue` | #CollectorTransformer passes native OpenTelemetryCollector resources through with OPM context applied (name prefix, namespace, labels) |
| `#InstrumentationTransformer` | `providers/kubernetes/transformers/instrumentation_transformer.cue` | #InstrumentationTransformer passes Instrumentation resources through with OPM context applied (name prefix, namespace, labels) |
| `#OpAMPBridgeTransformer` | `providers/kubernetes/transformers/op_amp_bridge_transformer.cue` | #OpAMPBridgeTransformer passes OpAMPBridge resources through with OPM context applied (name prefix, namespace, labels) |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |

---

## Resources

### telemetry

| Definition | File | Description |
|---|---|---|
| `#Collector` | `resources/telemetry/collector.cue` |  |
| `#CollectorDefaults` | `resources/telemetry/collector.cue` |  |
| `#CollectorResource` | `resources/telemetry/collector.cue` |  |
| `#Instrumentation` | `resources/telemetry/instrumentation.cue` |  |
| `#InstrumentationDefaults` | `resources/telemetry/instrumentation.cue` |  |
| `#InstrumentationResource` | `resources/telemetry/instrumentation.cue` |  |
| `#OpAMPBridge` | `resources/telemetry/op_amp_bridge.cue` |  |
| `#OpAMPBridgeDefaults` | `resources/telemetry/op_amp_bridge.cue` |  |
| `#OpAMPBridgeResource` | `resources/telemetry/op_amp_bridge.cue` |  |

---

## Schemas

### opentelemetry.io/instrumentation/v1alpha1

| Definition | File | Description |
|---|---|---|
| `#Instrumentation` | `schemas/opentelemetry.io/instrumentation/v1alpha1/types_gen.cue` |  |
| `#InstrumentationSpec` | `schemas/opentelemetry.io/instrumentation/v1alpha1/types_gen.cue` |  |

### opentelemetry.io/opampbridge/v1alpha1

| Definition | File | Description |
|---|---|---|
| `#OpAMPBridge` | `schemas/opentelemetry.io/opampbridge/v1alpha1/types_gen.cue` |  |
| `#OpAMPBridgeSpec` | `schemas/opentelemetry.io/opampbridge/v1alpha1/types_gen.cue` |  |

### opentelemetry.io/opentelemetrycollector/v1beta1

| Definition | File | Description |
|---|---|---|
| `#OpenTelemetryCollector` | `schemas/opentelemetry.io/opentelemetrycollector/v1beta1/types_gen.cue` |  |
| `#OpenTelemetryCollectorSpec` | `schemas/opentelemetry.io/opentelemetrycollector/v1beta1/types_gen.cue` |  |

---

