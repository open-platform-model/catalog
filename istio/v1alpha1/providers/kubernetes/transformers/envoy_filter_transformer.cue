package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#EnvoyFilterTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "envoy-filter-transformer"
		description: "Passes native Istio EnvoyFilter resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "envoy-filter"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#EnvoyFilterResource.metadata.fqn): res.#EnvoyFilterResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_ef:   #component.spec.envoyFilter
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1alpha3"
			kind:       "EnvoyFilter"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _ef.metadata != _|_ {
					if _ef.metadata.annotations != _|_ {
						annotations: _ef.metadata.annotations
					}
				}
			}
			if _ef.spec != _|_ {
				spec: _ef.spec
			}
		}
	}
}
