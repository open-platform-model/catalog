package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/gateway_api/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
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
