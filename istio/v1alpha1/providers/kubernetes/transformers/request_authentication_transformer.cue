package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/security@v1"
)

#RequestAuthenticationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "request-authentication-transformer"
		description: "Passes native Istio RequestAuthentication resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "request-authentication"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#RequestAuthenticationResource.metadata.fqn): res.#RequestAuthenticationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_ra:   #component.spec.requestAuthentication
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "security.istio.io/v1"
			kind:       "RequestAuthentication"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _ra.metadata != _|_ {
					if _ra.metadata.annotations != _|_ {
						annotations: _ra.metadata.annotations
					}
				}
			}
			if _ra.spec != _|_ {
				spec: _ra.spec
			}
		}
	}
}
