package network

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
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
