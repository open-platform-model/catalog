package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/otel_collector/v1alpha1/resources/telemetry@v1"
)

// #CollectorTransformer passes native OpenTelemetryCollector resources through
// with OPM context applied (name prefix, namespace, labels).
#CollectorTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/otel-collector/providers/kubernetes/transformers"
		version:     "v1"
		name:        "collector-transformer"
		description: "Passes native OpenTelemetryCollector resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "telemetry"
			"core.opmodel.dev/resource-type":     "collector"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#CollectorResource.metadata.fqn): res.#CollectorResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_col:  #component.spec.collector
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "opentelemetry.io/v1beta1"
			kind:       "OpenTelemetryCollector"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _col.metadata != _|_ {
					if _col.metadata.annotations != _|_ {
						annotations: _col.metadata.annotations
					}
				}
			}
			if _col.spec != _|_ {
				spec: _col.spec
			}
		}
	}
}
