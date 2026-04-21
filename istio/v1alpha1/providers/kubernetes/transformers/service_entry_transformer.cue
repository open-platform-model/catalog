package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#ServiceEntryTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "service-entry-transformer"
		description: "Passes native Istio ServiceEntry resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "service-entry"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ServiceEntryResource.metadata.fqn): res.#ServiceEntryResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_se:   #component.spec.serviceEntry
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "ServiceEntry"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _se.metadata != _|_ {
					if _se.metadata.annotations != _|_ {
						annotations: _se.metadata.annotations
					}
				}
			}
			if _se.spec != _|_ {
				spec: _se.spec
			}
		}
	}
}
