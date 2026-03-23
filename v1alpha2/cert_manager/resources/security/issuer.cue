package security

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
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

#IssuerComponent: component.#Component & {
	#resources: {(#IssuerResource.metadata.fqn): #IssuerResource}
}

#IssuerDefaults: schemas.#IssuerSchema
