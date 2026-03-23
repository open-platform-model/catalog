package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// TcpRoute Trait Definition
/////////////////////////////////////////////////////////////////

#TcpRouteTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/network"
		version:     "v1"
		name:        "tcp-route"
		description: "TCP port-forwarding rules for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #TcpRouteDefaults

	spec: close({tcpRoute: schemas.#TcpRouteSchema})
}

#TcpRoute: component.#Component & {
	#traits: {(#TcpRouteTrait.metadata.fqn): #TcpRouteTrait}
}

#TcpRouteDefaults: schemas.#TcpRouteSchema
