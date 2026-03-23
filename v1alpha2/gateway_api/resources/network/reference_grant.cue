package network

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/gateway_api/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ReferenceGrant Resource Definition
/////////////////////////////////////////////////////////////////

#ReferenceGrantResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "reference-grant"
		description: "A ReferenceGrant resource for cross-namespace Gateway API access"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #ReferenceGrantDefaults

	spec: close({referenceGrant: schemas.#ReferenceGrantSchema})
}

#ReferenceGrantComponent: component.#Component & {
	#resources: {(#ReferenceGrantResource.metadata.fqn): #ReferenceGrantResource}
}

#ReferenceGrantDefaults: schemas.#ReferenceGrantSchema
