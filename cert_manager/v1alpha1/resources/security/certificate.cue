package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
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
