package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	gwcV1 "gateway.networking.k8s.io/gatewayclass/v1"
)

// GatewayClassTransformer creates Gateway API GatewayClasses from GatewayClassResource components.
// GatewayClass is cluster-scoped so no namespace is emitted in metadata.
#GatewayClassTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "gateway-class-transformer"
		description: "Creates cluster-scoped Gateway API GatewayClasses from GatewayClassResource components"

		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "gateway-class"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/gateway-class@v1": _
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_gatewayClass: #component.spec.gatewayClass
		_name:         "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: gwcV1.#GatewayClass & {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "GatewayClass"
			metadata: {
				// GatewayClass is cluster-scoped — no namespace
				name:   _name
				labels: #context.labels
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				controllerName: _gatewayClass.controllerName
				if _gatewayClass.description != _|_ {
					description: _gatewayClass.description
				}
				if _gatewayClass.parametersRef != _|_ {
					parametersRef: _gatewayClass.parametersRef
				}
			}
		}
	}
}
