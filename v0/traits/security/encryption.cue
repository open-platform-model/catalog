package security

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Encryption Trait Definition
/////////////////////////////////////////////////////////////////

#EncryptionTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/security@v0"
		name:        "encryption"
		description: "Enforces encryption requirements"
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for encryption policy
	#defaults: #EncryptionDefaults

	#spec: encryption: {
		atRest!:    bool | *true
		inTransit!: bool | *true
	}
}

#Encryption: core.#Component & {
	#traits: {(#EncryptionTrait.metadata.fqn): #EncryptionTrait}
}

#EncryptionDefaults: {
	atRest:    true
	inTransit: true
}
