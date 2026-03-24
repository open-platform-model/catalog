package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/gateway_api/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// HttpRoute Resource Definition
/////////////////////////////////////////////////////////////////

#HttpRouteResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "http-route"
		description: "HTTP routing rules for a workload"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #HttpRouteDefaults

	spec: close({httpRoute: schemas.#HttpRouteSchema})
}

#HttpRouteComponent: component.#Component & {
	#resources: {(#HttpRouteResource.metadata.fqn): #HttpRouteResource}
}

#HttpRouteDefaults: schemas.#HttpRouteSchema
