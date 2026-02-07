package config

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// Secret Resource Definition
/////////////////////////////////////////////////////////////////

#SecretResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/config@v0"
		name:        "secret"
		description: "A Secret definition for sensitive configuration"
		labels: {}
	}

	// Default values for Secret resource
	#defaults: #SecretDefaults

	// OpenAPIv3-compatible schema defining the structure of the Secret spec
	#spec: secret: schemas.#SecretSchema
})

#Secret: close(core.#Component & {
	#resources: {(#SecretResource.metadata.fqn): #SecretResource}
})

#SecretDefaults: close(schemas.#SecretSchema & {
	type: "Opaque"
})
