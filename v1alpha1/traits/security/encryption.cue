package security

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Encryption Trait Definition
/////////////////////////////////////////////////////////////////

#EncryptionConfigTrait: core.#Trait & {
	metadata: {
		modulePath: "opmodel.dev/traits/security@v1"
		name:          "encryption"
		description:   "Enforces encryption requirements"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for encryption policy
	#defaults: #EncryptionConfigDefaults

	spec: close({encryption: schemas.#EncryptionConfigSchema})
}

#EncryptionConfig: core.#Component & {
	#traits: {(#EncryptionConfigTrait.metadata.fqn): #EncryptionConfigTrait}
}

#EncryptionConfigDefaults: schemas.#EncryptionConfigSchema & {
	atRest:    true
	inTransit: true
}
