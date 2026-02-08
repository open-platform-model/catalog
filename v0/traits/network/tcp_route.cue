package network

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// TcpRoute Trait Definition
/////////////////////////////////////////////////////////////////

#TcpRouteTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/network@v0"
		name:        "tcp-route"
		description: "TCP port-forwarding rules for a workload"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #TcpRouteDefaults

	#spec: tcpRoute: schemas.#TcpRouteSchema
})

#TcpRoute: close(core.#Component & {
	#traits: {(#TcpRouteTrait.metadata.fqn): #TcpRouteTrait}
})

#TcpRouteDefaults: close(schemas.#TcpRouteSchema & {
	rules: [{backendPort: 8080}]
})
