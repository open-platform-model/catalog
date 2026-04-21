package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/security@v1"
)

#PeerAuthenticationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "peer-authentication-transformer"
		description: "Passes native Istio PeerAuthentication resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "peer-authentication"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#PeerAuthenticationResource.metadata.fqn): res.#PeerAuthenticationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_pa:   #component.spec.peerAuthentication
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "security.istio.io/v1"
			kind:       "PeerAuthentication"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _pa.metadata != _|_ {
					if _pa.metadata.annotations != _|_ {
						annotations: _pa.metadata.annotations
					}
				}
			}
			if _pa.spec != _|_ {
				spec: _pa.spec
			}
		}
	}
}
