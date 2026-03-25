package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/gateway_api/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// TlsRoute Resource Definition
/////////////////////////////////////////////////////////////////

#TlsRouteResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "tls-route"
		description: "TLS routing rules (passthrough or terminate) for a workload"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #TlsRouteDefaults

	spec: close({tlsRoute: schemas.#TlsRouteSchema})
}

#TlsRoute: component.#Component & {
	#resources: {(#TlsRouteResource.metadata.fqn): #TlsRouteResource}
}

#TlsRouteDefaults: schemas.#TlsRouteSchema
