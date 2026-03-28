package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	hr "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.k8s.io/httproute/v1@v1"
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

	spec: close({httpRoute: {
		metadata?: _#metadata
		spec?:     hr.#HTTPRouteSpec
	}})
}

#HttpRoute: component.#Component & {
	#resources: {(#HttpRouteResource.metadata.fqn): #HttpRouteResource}
}

#HttpRouteDefaults: {
	metadata?: _#metadata
	spec?:     hr.#HTTPRouteSpec
}
