package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	gw "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/gateway/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// Gateway Resource Definition
/////////////////////////////////////////////////////////////////

#GatewayResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "gateway"
		description: "A Gateway resource (Gateway API)"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #GatewayDefaults

	spec: close({gateway: {
		metadata?: _#metadata
		spec?:     gw.#GatewaySpec
	}})
}

#Gateway: component.#Component & {
	#resources: {(#GatewayResource.metadata.fqn): #GatewayResource}
}

#GatewayDefaults: {
	metadata?: _#metadata
	spec?:     gw.#GatewaySpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
