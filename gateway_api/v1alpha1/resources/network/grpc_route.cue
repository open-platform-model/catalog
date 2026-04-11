package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	gr "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/grpcroute/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// GrpcRoute Resource Definition
/////////////////////////////////////////////////////////////////

#GrpcRouteResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "grpc-route"
		description: "gRPC routing rules for a workload"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #GrpcRouteDefaults

	spec: close({grpcRoute: {
		metadata?: _#metadata
		spec?:     gr.#GRPCRouteSpec
	}})
}

#GrpcRoute: component.#Component & {
	#resources: {(#GrpcRouteResource.metadata.fqn): #GrpcRouteResource}
}

#GrpcRouteDefaults: {
	metadata?: _#metadata
	spec?:     gr.#GRPCRouteSpec
}
