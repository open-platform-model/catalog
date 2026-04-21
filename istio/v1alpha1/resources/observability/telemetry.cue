package observability

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	tm "opmodel.dev/istio/v1alpha1/schemas/istio/telemetry.istio.io/telemetry/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// Telemetry Resource Definition
/////////////////////////////////////////////////////////////////

#TelemetryResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/observability"
		version:     "v1"
		name:        "telemetry"
		description: "An Istio Telemetry resource — access logs, metrics, and tracing configuration per workload"
		labels: {
			"resource.opmodel.dev/category": "observability"
		}
	}

	#defaults: #TelemetryDefaults

	spec: close({telemetry: {
		metadata?: _#metadata
		spec?:     tm.#TelemetrySpec
	}})
}

#Telemetry: component.#Component & {
	#resources: {(#TelemetryResource.metadata.fqn): #TelemetryResource}
}

#TelemetryDefaults: {
	metadata?: _#metadata
	spec?:     tm.#TelemetrySpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
