package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// TlsRoute Trait Definition
/////////////////////////////////////////////////////////////////

#TlsRouteTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/network"
		version:     "v1"
		name:        "tls-route"
		description: "TLS routing rules (passthrough or terminate) for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #TlsRouteDefaults

	spec: close({tlsRoute: schemas.#TlsRouteSchema})
}

#TlsRoute: component.#Component & {
	#traits: {(#TlsRouteTrait.metadata.fqn): #TlsRouteTrait}
}

#TlsRouteDefaults: schemas.#TlsRouteSchema
