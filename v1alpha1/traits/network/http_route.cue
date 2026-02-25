package network

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// HttpRoute Trait Definition
/////////////////////////////////////////////////////////////////

#HttpRouteTrait: core.#Trait & {
	metadata: {
		cueModulePath: "opmodel.dev/traits/network@v1"
		name:          "http-route"
		description:   "HTTP routing rules for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #HttpRouteDefaults

	spec: close({httpRoute: schemas.#HttpRouteSchema})
}

#HttpRoute: core.#Component & {
	#traits: {(#HttpRouteTrait.metadata.fqn): #HttpRouteTrait}
}

#HttpRouteDefaults: schemas.#HttpRouteSchema
