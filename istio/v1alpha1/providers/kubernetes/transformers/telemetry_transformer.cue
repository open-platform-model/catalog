package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/observability@v1"
)

#TelemetryTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "telemetry-transformer"
		description: "Passes native Istio Telemetry resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "observability"
			"core.opmodel.dev/resource-type":     "telemetry"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#TelemetryResource.metadata.fqn): res.#TelemetryResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_tm:   #component.spec.telemetry
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "telemetry.istio.io/v1"
			kind:       "Telemetry"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _tm.metadata != _|_ {
					if _tm.metadata.annotations != _|_ {
						annotations: _tm.metadata.annotations
					}
				}
			}
			if _tm.spec != _|_ {
				spec: _tm.spec
			}
		}
	}
}
