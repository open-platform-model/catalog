package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #GatewayTransformer passes native Gateway API Gateway resources through
// with OPM context applied (name prefix, namespace, labels).
#GatewayTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "gateway-transformer"
		description: "Passes native Gateway API Gateway resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "gateway"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#GatewayResource.metadata.fqn): res.#GatewayResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_gateway: #component.spec.gateway
		_name:    "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "Gateway"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _gateway.metadata != _|_ {
					if _gateway.metadata.annotations != _|_ {
						annotations: _gateway.metadata.annotations
					}
				}
			}
			if _gateway.spec != _|_ {
				spec: _gateway.spec
			}
		}
	}
}
