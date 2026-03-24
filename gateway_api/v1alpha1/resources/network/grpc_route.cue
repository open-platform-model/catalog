package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/gateway_api/v1alpha1/schemas@v1"
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

	spec: close({grpcRoute: schemas.#GrpcRouteSchema})
}

#GrpcRouteComponent: component.#Component & {
	#resources: {(#GrpcRouteResource.metadata.fqn): #GrpcRouteResource}
}

#GrpcRouteDefaults: schemas.#GrpcRouteSchema
