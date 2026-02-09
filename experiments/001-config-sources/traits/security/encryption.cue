package security

import (
	core "example.com/config-sources/core"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// Encryption Trait Definition
/////////////////////////////////////////////////////////////////

#EncryptionTrait: close(core.#Trait & {
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
})

#Encryption: close(core.#Component & {
	#traits: {(#EncryptionTrait.metadata.fqn): #EncryptionTrait}
})

#EncryptionDefaults: close({
	atRest:    true
	inTransit: true
})
