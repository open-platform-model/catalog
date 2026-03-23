package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/gateway_api/schemas@v1"
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

	spec: close({gateway: schemas.#GatewaySchema})
}

#GatewayComponent: component.#Component & {
	#resources: {(#GatewayResource.metadata.fqn): #GatewayResource}
}

#GatewayDefaults: schemas.#GatewaySchema
