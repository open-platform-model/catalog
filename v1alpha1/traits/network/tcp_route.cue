package network

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// TcpRoute Trait Definition
/////////////////////////////////////////////////////////////////

#TcpRouteTrait: core.#Trait & {
	metadata: {
		cueModulePath: "opmodel.dev/traits/network@v1"
		name:          "tcp-route"
		description:   "TCP port-forwarding rules for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #TcpRouteDefaults

	spec: close({tcpRoute: schemas.#TcpRouteSchema})
}

#TcpRoute: core.#Component & {
	#traits: {(#TcpRouteTrait.metadata.fqn): #TcpRouteTrait}
}

#TcpRouteDefaults: schemas.#TcpRouteSchema
