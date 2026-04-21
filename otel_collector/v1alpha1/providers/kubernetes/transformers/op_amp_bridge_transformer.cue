package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/otel_collector/v1alpha1/resources/telemetry@v1"
)

// #OpAMPBridgeTransformer passes OpAMPBridge resources through
// with OPM context applied (name prefix, namespace, labels).
#OpAMPBridgeTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/otel-collector/providers/kubernetes/transformers"
		version:     "v1"
		name:        "op-amp-bridge-transformer"
		description: "Passes native OpAMPBridge resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "telemetry"
			"core.opmodel.dev/resource-type":     "op-amp-bridge"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#OpAMPBridgeResource.metadata.fqn): res.#OpAMPBridgeResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_bridge: #component.spec.opAmpBridge
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "opentelemetry.io/v1alpha1"
			kind:       "OpAMPBridge"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _bridge.metadata != _|_ {
					if _bridge.metadata.annotations != _|_ {
						annotations: _bridge.metadata.annotations
					}
				}
			}
			if _bridge.spec != _|_ {
				spec: _bridge.spec
			}
		}
	}
}
