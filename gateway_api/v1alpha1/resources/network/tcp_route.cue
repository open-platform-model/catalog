package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/gateway_api/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// TcpRoute Resource Definition
/////////////////////////////////////////////////////////////////

#TcpRouteResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "tcp-route"
		description: "TCP port-forwarding rules for a workload"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #TcpRouteDefaults

	spec: close({tcpRoute: schemas.#TcpRouteSchema})
}

#TcpRoute: component.#Component & {
	#resources: {(#TcpRouteResource.metadata.fqn): #TcpRouteResource}
}

#TcpRouteDefaults: schemas.#TcpRouteSchema
