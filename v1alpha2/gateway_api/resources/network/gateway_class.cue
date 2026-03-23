package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/gateway_api/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// GatewayClass Resource Definition
/////////////////////////////////////////////////////////////////

#GatewayClassResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "gateway-class"
		description: "A GatewayClass resource defining a class of Gateways"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #GatewayClassDefaults

	spec: close({gatewayClass: schemas.#GatewayClassSchema})
}

#GatewayClassComponent: component.#Component & {
	#resources: {(#GatewayClassResource.metadata.fqn): #GatewayClassResource}
}

#GatewayClassDefaults: schemas.#GatewayClassSchema
