package network

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
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
