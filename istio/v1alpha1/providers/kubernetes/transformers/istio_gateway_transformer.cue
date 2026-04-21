package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/network@v1"
)

#IstioGatewayTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "istio-gateway-transformer"
		description: "Passes native Istio Gateway (networking.istio.io) resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "istio-gateway"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#IstioGatewayResource.metadata.fqn): res.#IstioGatewayResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_gw:   #component.spec.istioGateway
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.istio.io/v1"
			kind:       "Gateway"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _gw.metadata != _|_ {
					if _gw.metadata.annotations != _|_ {
						annotations: _gw.metadata.annotations
					}
				}
			}
			if _gw.spec != _|_ {
				spec: _gw.spec
			}
		}
	}
}
