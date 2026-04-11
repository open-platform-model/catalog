package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Encryption Trait Definition
/////////////////////////////////////////////////////////////////

#EncryptionConfigTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/security"
		version:     "v1"
		name:        "encryption"
		description: "Enforces encryption requirements"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for encryption policy
	#defaults: #EncryptionConfigDefaults

	spec: close({encryption: schemas.#EncryptionConfigSchema})
}

#EncryptionConfig: component.#Component & {
	#traits: {(#EncryptionConfigTrait.metadata.fqn): #EncryptionConfigTrait}
}

#EncryptionConfigDefaults: schemas.#EncryptionConfigSchema & {
	atRest:    true
	inTransit: true
}
