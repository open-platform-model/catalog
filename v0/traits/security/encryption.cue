package security

import (
	core "opm.dev/core@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Encryption Trait Definition
/////////////////////////////////////////////////////////////////

#EncryptionTrait: close(core.#TraitDefinition & {
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

#Encryption: close(core.#ComponentDefinition & {
	#traits: {(#EncryptionTrait.metadata.fqn): #EncryptionTrait}
})

#EncryptionDefaults: close({
	atRest:    true
	inTransit: true
})
