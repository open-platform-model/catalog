package network

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
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
