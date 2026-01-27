package security

import (
	core "opm.dev/core@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Encryption Trait Definition
/////////////////////////////////////////////////////////////////

#EncryptionTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opm.dev/traits/security@v0"
		name:        "Encryption"
		description: "Enforces encryption requirements"
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for encryption policy
	#defaults: #EncryptionDefaults

	#spec: encryption: {
		atRest!:    bool | *true
		inTransit!: bool | *true
	}
})

#Encryption: close(core.#Component & {
	#traits: {(#EncryptionTrait.metadata.fqn): #EncryptionTrait}
})

#EncryptionDefaults: close({
	atRest:    true
	inTransit: true
})
