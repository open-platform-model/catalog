package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ServiceAccount Resource Definition
/////////////////////////////////////////////////////////////////

#ServiceAccountResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/resources/security"
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
