package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#DestinationRuleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "destination-rule-transformer"
		description: "Passes native Istio DestinationRule resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "destination-rule"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#DestinationRuleResource.metadata.fqn): res.#DestinationRuleResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_dr:   #component.spec.destinationRule
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "DestinationRule"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _dr.metadata != _|_ {
					if _dr.metadata.annotations != _|_ {
						annotations: _dr.metadata.annotations
					}
				}
			}
			if _dr.spec != _|_ {
				spec: _dr.spec
			}
		}
	}
}
