package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	network_resources "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
	tcpRouteV1alpha2 "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/tcproute/v1alpha2@v1"
)

// TcpRouteTransformer creates Gateway API TCPRoutes from components with TcpRoute trait
#TcpRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "tcp-route-transformer"
		description: "Creates Gateway API TCPRoutes for components with TcpRoute trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "tcp-route"
		}
	}

	requiredLabels: {}
	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/tcp-route@v1": network_resources.#TcpRouteResource
	}
	optionalResources: {}

	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_tcpRoute: #component.spec.tcpRoute
		_name:     "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		_routeAnnotations: {
			if len(#context.componentAnnotations) > 0 {
				#context.componentAnnotations
			}
		}

		output: tcpRouteV1alpha2.#TCPRoute & {
			apiVersion: "gateway.networking.k8s.io/v1alpha2"
			kind:       "TCPRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(_routeAnnotations) > 0 {
					annotations: _routeAnnotations
				}
			}
			spec: {
				if _tcpRoute.gatewayRef != _|_ {
					parentRefs: [{
						name: _tcpRoute.gatewayRef.name
						if _tcpRoute.gatewayRef.namespace != _|_ {
							namespace: _tcpRoute.gatewayRef.namespace
						}
					}]
				}

				rules: [for rule in _tcpRoute.rules {
					backendRefs: [{
						name: _name
						port: rule.backendPort
					}]
				}]
			}
		}
	}
}
