package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// GrpcRoute Trait Definition
/////////////////////////////////////////////////////////////////

#GrpcRouteTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/network@v0"
		name:        "grpc-route"
		description: "gRPC routing rules for a workload"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #GrpcRouteDefaults

	#spec: grpcRoute: schemas.#GrpcRouteSchema
})

#GrpcRoute: close(core.#Component & {
	#traits: {(#GrpcRouteTrait.metadata.fqn): #GrpcRouteTrait}
})

#GrpcRouteDefaults: close(schemas.#GrpcRouteSchema & {
	rules: [{backendPort: 9090}]
})
