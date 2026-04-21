package telemetry

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	otc "opmodel.dev/otel_collector/v1alpha1/schemas/opentelemetry.io/opentelemetrycollector/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// OpenTelemetryCollector Resource Definition
/////////////////////////////////////////////////////////////////

#CollectorResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/otel-collector/resources/telemetry"
		version:     "v1"
		name:        "collector"
		description: "An OpenTelemetryCollector managed by the OTEL operator (opentelemetry.io/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "telemetry"
		}
	}

	#defaults: #CollectorDefaults

	spec: close({collector: {
		metadata?: _#metadata
		spec?:     otc.#OpenTelemetryCollectorSpec
	}})
}

#Collector: component.#Component & {
	#resources: {(#CollectorResource.metadata.fqn): #CollectorResource}
}

#CollectorDefaults: {
	metadata?: _#metadata
	spec?:     otc.#OpenTelemetryCollectorSpec
}
