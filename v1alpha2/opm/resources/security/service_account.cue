package security

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ServiceAccount Resource Definition
/////////////////////////////////////////////////////////////////

#ServiceAccountResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/resources/security"
		version:     "v1"
		name:        "service-account"
		description: "A standalone ServiceAccount definition for identity"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	// Default values for ServiceAccount resource
	#defaults: #ServiceAccountDefaults

	// OpenAPIv3-compatible schema defining the structure of the ServiceAccount spec
	spec: close({serviceAccount: schemas.#ServiceAccountSchema})
}

#ServiceAccount: component.#Component & {
	#resources: {(#ServiceAccountResource.metadata.fqn): #ServiceAccountResource}
}

#ServiceAccountDefaults: schemas.#ServiceAccountSchema & {
	automountToken: false
}
