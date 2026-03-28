package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	tr "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/tcproute/v1alpha2@v1"
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

	spec: close({tcpRoute: {
		metadata?: _#metadata
		spec?:     tr.#TCPRouteSpec
	}})
}

#TcpRoute: component.#Component & {
	#resources: {(#TcpRouteResource.metadata.fqn): #TcpRouteResource}
}

#TcpRouteDefaults: {
	metadata?: _#metadata
	spec?:     tr.#TCPRouteSpec
}
