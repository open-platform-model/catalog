package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Issuer Resource Definition
/////////////////////////////////////////////////////////////////

#IssuerResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/cert-manager/resources/security"
		version:     "v1"
		name:        "issuer"
		description: "A cert-manager Issuer (namespace-scoped certificate authority)"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	#defaults: #IssuerDefaults

	spec: close({issuer: schemas.#IssuerSchema})
}

#Issuer: component.#Component & {
	#resources: {(#IssuerResource.metadata.fqn): #IssuerResource}
}

#IssuerDefaults: schemas.#IssuerSchema
