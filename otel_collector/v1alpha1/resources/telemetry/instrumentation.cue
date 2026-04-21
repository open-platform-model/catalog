package telemetry

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	otin "opmodel.dev/otel_collector/v1alpha1/schemas/opentelemetry.io/instrumentation/v1alpha1@v1"
)

/////////////////////////////////////////////////////////////////
//// Instrumentation Resource Definition
/////////////////////////////////////////////////////////////////

#InstrumentationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/otel-collector/resources/telemetry"
		version:     "v1"
		name:        "instrumentation"
		description: "Auto-instrumentation configuration for OTEL sidecar injection (opentelemetry.io/v1alpha1)"
		labels: {
			"resource.opmodel.dev/category": "telemetry"
		}
	}

	#defaults: #InstrumentationDefaults

	spec: close({instrumentation: {
		metadata?: _#metadata
		spec?:     otin.#InstrumentationSpec
	}})
}

#Instrumentation: component.#Component & {
	#resources: {(#InstrumentationResource.metadata.fqn): #InstrumentationResource}
}

#InstrumentationDefaults: {
	metadata?: _#metadata
	spec?:     otin.#InstrumentationSpec
}
