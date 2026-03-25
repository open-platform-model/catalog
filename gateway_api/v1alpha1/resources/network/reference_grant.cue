package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/gateway_api/v1alpha1/schemas@v1"
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

#ReferenceGrant: component.#Component & {
	#resources: {(#ReferenceGrantResource.metadata.fqn): #ReferenceGrantResource}
}

#ReferenceGrantDefaults: schemas.#ReferenceGrantSchema
