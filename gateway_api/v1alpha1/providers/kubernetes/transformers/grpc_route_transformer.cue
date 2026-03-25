package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #GrpcRouteTransformer passes native Gateway API GRPCRoute resources through
// with OPM context applied (name prefix, namespace, labels).
#GrpcRouteTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "grpc-route-transformer"
		description: "Passes native Gateway API GRPCRoute resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "grpc-route"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#GrpcRouteResource.metadata.fqn): res.#GrpcRouteResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_grpcRoute: #component.spec.grpcRoute
		_name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "GRPCRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _grpcRoute.metadata != _|_ {
					if _grpcRoute.metadata.annotations != _|_ {
						annotations: _grpcRoute.metadata.annotations
					}
				}
			}
			if _grpcRoute.spec != _|_ {
				spec: _grpcRoute.spec
			}
		}
	}
}
