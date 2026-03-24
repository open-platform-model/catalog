package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/gateway_api/v1alpha1/schemas@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// GrpcRoute Trait Definition
/////////////////////////////////////////////////////////////////

#GrpcRouteTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/traits/network"
		version:     "v1"
		name:        "grpc-route"
		description: "gRPC routing rules for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #GrpcRouteDefaults

	spec: close({grpcRoute: schemas.#GrpcRouteSchema})
}

#GrpcRoute: component.#Component & {
	#traits: {(#GrpcRouteTrait.metadata.fqn): #GrpcRouteTrait}
}

#GrpcRouteDefaults: schemas.#GrpcRouteSchema
