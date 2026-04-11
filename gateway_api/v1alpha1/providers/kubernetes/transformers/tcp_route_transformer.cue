package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #TcpRouteTransformer passes native Gateway API TCPRoute resources through
// with OPM context applied (name prefix, namespace, labels).
#TcpRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "tcp-route-transformer"
		description: "Passes native Gateway API TCPRoute resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "tcp-route"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#TcpRouteResource.metadata.fqn): res.#TcpRouteResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_tcpRoute: #component.spec.tcpRoute
		_name:     "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1alpha2"
			kind:       "TCPRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _tcpRoute.metadata != _|_ {
					if _tcpRoute.metadata.annotations != _|_ {
						annotations: _tcpRoute.metadata.annotations
					}
				}
			}
			if _tcpRoute.spec != _|_ {
				spec: _tcpRoute.spec
			}
		}
	}
}
