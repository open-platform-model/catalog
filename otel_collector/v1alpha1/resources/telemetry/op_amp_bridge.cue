package telemetry

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	opamp "opmodel.dev/otel_collector/v1alpha1/schemas/opentelemetry.io/opampbridge/v1alpha1@v1"
)

/////////////////////////////////////////////////////////////////
//// OpAMPBridge Resource Definition
/////////////////////////////////////////////////////////////////

#OpAMPBridgeResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/otel-collector/resources/telemetry"
		version:     "v1"
		name:        "op-amp-bridge"
		description: "OpAMP control-plane bridge for OTEL fleet management (opentelemetry.io/v1alpha1)"
		labels: {
			"resource.opmodel.dev/category": "telemetry"
		}
	}

	#defaults: #OpAMPBridgeDefaults

	spec: close({opAmpBridge: {
		metadata?: _#metadata
		spec?:     opamp.#OpAMPBridgeSpec
	}})
}

#OpAMPBridge: component.#Component & {
	#resources: {(#OpAMPBridgeResource.metadata.fqn): #OpAMPBridgeResource}
}

#OpAMPBridgeDefaults: {
	metadata?: _#metadata
	spec?:     opamp.#OpAMPBridgeSpec
}
