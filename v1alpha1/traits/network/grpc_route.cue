package network

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// GrpcRoute Trait Definition
/////////////////////////////////////////////////////////////////

#GrpcRouteTrait: core.#Trait & {
	metadata: {
		cueModulePath: "opmodel.dev/traits/network@v1"
		name:          "grpc-route"
		description:   "gRPC routing rules for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #GrpcRouteDefaults

	spec: close({grpcRoute: schemas.#GrpcRouteSchema})
}

#GrpcRoute: core.#Component & {
	#traits: {(#GrpcRouteTrait.metadata.fqn): #GrpcRouteTrait}
}

#GrpcRouteDefaults: schemas.#GrpcRouteSchema
