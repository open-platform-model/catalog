package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// HttpRoute Trait Definition
/////////////////////////////////////////////////////////////////

#HttpRouteTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/network@v0"
		name:        "http-route"
		description: "HTTP routing rules for a workload"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #HttpRouteDefaults

	#spec: httpRoute: schemas.#HttpRouteSchema
})

#HttpRoute: close(core.#Component & {
	#traits: {(#HttpRouteTrait.metadata.fqn): #HttpRouteTrait}
})

#HttpRouteDefaults: close(schemas.#HttpRouteSchema & {
	rules: [{backendPort: 8080}]
})
