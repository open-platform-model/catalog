package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/otel_collector/v1alpha1/resources/telemetry@v1"
)

// #InstrumentationTransformer passes Instrumentation resources through
// with OPM context applied (name prefix, namespace, labels).
#InstrumentationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/otel-collector/providers/kubernetes/transformers"
		version:     "v1"
		name:        "instrumentation-transformer"
		description: "Passes native Instrumentation resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "telemetry"
			"core.opmodel.dev/resource-type":     "instrumentation"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#InstrumentationResource.metadata.fqn): res.#InstrumentationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_in:   #component.spec.instrumentation
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "opentelemetry.io/v1alpha1"
			kind:       "Instrumentation"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _in.metadata != _|_ {
					if _in.metadata.annotations != _|_ {
						annotations: _in.metadata.annotations
					}
				}
			}
			if _in.spec != _|_ {
				spec: _in.spec
			}
		}
	}
}
