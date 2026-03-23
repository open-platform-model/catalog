package transformers

import (
	transformer "opmodel.dev/opm/core/transformer@v1"
	network_traits "opmodel.dev/opm/traits/network@v1"
)

// TlsRouteTransformer creates Gateway API TLSRoutes from components with TlsRoute trait
#TlsRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "tls-route-transformer"
		description: "Creates Gateway API TLSRoutes for components with TlsRoute trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "tls-route"
		}
	}

	requiredLabels:    {}
	requiredResources: {}
	optionalResources: {}

	requiredTraits: {
		"opmodel.dev/opm/traits/network/tls-route@v1": network_traits.#TlsRouteTrait
	}
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

		output: {
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
