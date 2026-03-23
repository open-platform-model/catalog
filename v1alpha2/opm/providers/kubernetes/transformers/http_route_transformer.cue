package transformers

import (
	transformer "opmodel.dev/opm/core/transformer@v1"
	network_traits "opmodel.dev/opm/traits/network@v1"
)

// HttpRouteTransformer creates Gateway API HTTPRoutes from components with HttpRoute trait
#HttpRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "http-route-transformer"
		description: "Creates Gateway API HTTPRoutes for components with HttpRoute trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "http-route"
		}
	}

	requiredLabels:    {}
	requiredResources: {}
	optionalResources: {}

	requiredTraits: {
		"opmodel.dev/opm/traits/network/http-route@v1": network_traits.#HttpRouteTrait
	}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_httpRoute: #component.spec.httpRoute
		_name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		_routeAnnotations: {
			if len(#context.componentAnnotations) > 0 {
				#context.componentAnnotations
			}
		}

		output: {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "HTTPRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(_routeAnnotations) > 0 {
					annotations: _routeAnnotations
				}
			}
			spec: {
				if _httpRoute.gatewayRef != _|_ {
					parentRefs: [{
						name: _httpRoute.gatewayRef.name
						if _httpRoute.gatewayRef.namespace != _|_ {
							namespace: _httpRoute.gatewayRef.namespace
						}
					}]
				}

				if _httpRoute.hostnames != _|_ {
					hostnames: _httpRoute.hostnames
				}

				rules: [for rule in _httpRoute.rules {
					backendRefs: [{
						name: _name
						port: rule.backendPort
					}]
					if rule.matches != _|_ {
						matches: [for m in rule.matches {
							if m.path != _|_ {
								path: {
									type:  m.path.type
									value: m.path.value
								}
							}
							if m.method != _|_ {
								method: m.method
							}
						}]
					}
				}]
			}
		}
	}
}
