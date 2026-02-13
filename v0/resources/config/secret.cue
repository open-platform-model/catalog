package config

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// Secrets Resource Definition
/////////////////////////////////////////////////////////////////

#SecretsResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/config@v0"
		name:        "secrets"
		description: "A Secret definition for sensitive configuration"
	}

	// Default values for Secrets resource
	#defaults: #SecretsDefaults

	// OpenAPIv3-compatible schema defining the structure of the Secrets spec
	#spec: secrets: [name=string]: schemas.#SecretSchema
})

#Secrets: close(core.#Component & {
	metadata: annotations: {
		"transformer.opmodel.dev/list-output": true
	}

	#resources: {(#SecretsResource.metadata.fqn): #SecretsResource}
})

#SecretsDefaults: close(schemas.#SecretSchema & {
	type: "Opaque"
})
