package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	network_resources "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
	tlsRouteV1alpha2 "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/tlsroute/v1alpha2@v1"
)

// TlsRouteTransformer creates Gateway API TLSRoutes from components with TlsRoute trait
#TlsRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "tls-route-transformer"
		description: "Creates Gateway API TLSRoutes for components with TlsRoute trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "tls-route"
		}
	}

	requiredLabels: {}
	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/tls-route@v1": network_resources.#TlsRouteResource
	}
	optionalResources: {}

	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_tlsRoute: #component.spec.tlsRoute
		_name:     "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		_routeAnnotations: {
			if len(#context.componentAnnotations) > 0 {
				#context.componentAnnotations
			}
		}

		output: tlsRouteV1alpha2.#TLSRoute & {
			apiVersion: "gateway.networking.k8s.io/v1alpha2"
			kind:       "TLSRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(_routeAnnotations) > 0 {
					annotations: _routeAnnotations
				}
			}
			spec: {
				if _tlsRoute.gatewayRef != _|_ {
					parentRefs: [{
						name: _tlsRoute.gatewayRef.name
						if _tlsRoute.gatewayRef.namespace != _|_ {
							namespace: _tlsRoute.gatewayRef.namespace
						}
					}]
				}

				if _tlsRoute.hostnames != _|_ {
					hostnames: _tlsRoute.hostnames
				}

				rules: [for rule in _tlsRoute.rules {
					backendRefs: [{
						name: _name
						port: rule.backendPort
					}]
				}]
			}
		}
	}
}
