package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/security@v1"
)

#AuthorizationPolicyTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "authorization-policy-transformer"
		description: "Passes native Istio AuthorizationPolicy resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "authorization-policy"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#AuthorizationPolicyResource.metadata.fqn): res.#AuthorizationPolicyResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_ap:   #component.spec.authorizationPolicy
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "security.istio.io/v1"
			kind:       "AuthorizationPolicy"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _ap.metadata != _|_ {
					if _ap.metadata.annotations != _|_ {
						annotations: _ap.metadata.annotations
					}
				}
			}
			if _ap.spec != _|_ {
				spec: _ap.spec
			}
		}
	}
}
