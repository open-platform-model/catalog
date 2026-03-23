package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/gateway_api/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// BackendTrafficPolicy Resource Definition
/////////////////////////////////////////////////////////////////

#BackendTrafficPolicyResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "backend-traffic-policy"
		description: "A BackendTrafficPolicy resource for configuring backend traffic"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #BackendTrafficPolicyDefaults

	spec: close({backendTrafficPolicy: schemas.#BackendTrafficPolicySchema})
}

#BackendTrafficPolicyComponent: component.#Component & {
	#resources: {(#BackendTrafficPolicyResource.metadata.fqn): #BackendTrafficPolicyResource}
}

#BackendTrafficPolicyDefaults: schemas.#BackendTrafficPolicySchema
