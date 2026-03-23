package security

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Certificate Resource Definition
/////////////////////////////////////////////////////////////////

#CertificateResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/cert-manager/resources/security"
		version:     "v1"
		name:        "certificate"
		description: "A cert-manager Certificate resource requesting a TLS certificate"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	#defaults: #CertificateDefaults

	spec: close({certificate: schemas.#CertificateSchema})
}

#CertificateComponent: component.#Component & {
	#resources: {(#CertificateResource.metadata.fqn): #CertificateResource}
}

#CertificateDefaults: schemas.#CertificateSchema
