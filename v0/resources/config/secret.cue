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
		labels: {}
		annotations: {
			"transformer.opmodel.dev/list-output": true
		}
	}

	// Default values for Secrets resource
	#defaults: #SecretsDefaults

	// OpenAPIv3-compatible schema defining the structure of the Secrets spec
	#spec: secrets: [name=string]: schemas.#SecretSchema & {type: string | *"Opaque"}
})

#Secrets: close(core.#Component & {
	#resources: {(#SecretsResource.metadata.fqn): #SecretsResource}
})

#SecretsDefaults: close(schemas.#SecretSchema & {
	type: "Opaque"
})
