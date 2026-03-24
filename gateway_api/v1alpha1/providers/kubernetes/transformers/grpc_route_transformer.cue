package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	network_resources "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
	grpcRouteV1 "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/grpcroute/v1@v1"
)

// GrpcRouteTransformer creates Gateway API GRPCRoutes from components with GrpcRoute trait
#GrpcRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "grpc-route-transformer"
		description: "Creates Gateway API GRPCRoutes for components with GrpcRoute trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "grpc-route"
		}
	}

	requiredLabels: {}
	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/grpc-route@v1": network_resources.#GrpcRouteResource
	}
	optionalResources: {}

	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_grpcRoute: #component.spec.grpcRoute
		_name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		_routeAnnotations: {
			if len(#context.componentAnnotations) > 0 {
				#context.componentAnnotations
			}
		}

		output: grpcRouteV1.#GRPCRoute & {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "GRPCRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(_routeAnnotations) > 0 {
					annotations: _routeAnnotations
				}
			}
			spec: {
				if _grpcRoute.gatewayRef != _|_ {
					parentRefs: [{
						name: _grpcRoute.gatewayRef.name
						if _grpcRoute.gatewayRef.namespace != _|_ {
							namespace: _grpcRoute.gatewayRef.namespace
						}
					}]
				}

				if _grpcRoute.hostnames != _|_ {
					hostnames: _grpcRoute.hostnames
				}

				rules: [for rule in _grpcRoute.rules {
					backendRefs: [{
						name: _name
						port: rule.backendPort
					}]
					if rule.matches != _|_ {
						matches: [for m in rule.matches {
							method: {
								if m.service != _|_ {
									service: m.service
								}
								if m.method != _|_ {
									method: m.method
								}
							}
						}]
					}
				}]
			}
		}
	}
}
