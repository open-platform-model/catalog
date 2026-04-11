package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #GatewayClassTransformer passes native Gateway API GatewayClass resources through
// with OPM context applied (name prefix, labels). GatewayClass is cluster-scoped — no namespace.
#GatewayClassTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "gateway-class-transformer"
		description: "Passes native Gateway API GatewayClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "gateway-class"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#GatewayClassResource.metadata.fqn): res.#GatewayClassResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_gatewayClass: #component.spec.gatewayClass
		_name:         "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "GatewayClass"
			metadata: {
				// GatewayClass is cluster-scoped — no namespace
				name:   _name
				labels: #context.labels
				if _gatewayClass.metadata != _|_ {
					if _gatewayClass.metadata.annotations != _|_ {
						annotations: _gatewayClass.metadata.annotations
					}
				}
			}
			if _gatewayClass.spec != _|_ {
				spec: _gatewayClass.spec
			}
		}
	}
}
