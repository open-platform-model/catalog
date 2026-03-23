package config

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Secrets Resource Definition
/////////////////////////////////////////////////////////////////

#SecretsResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/resources/config"
		version:     "v1"
		name:        "secrets"
		description: "A Secret definition for sensitive configuration"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	// Default values for Secrets resource
	#defaults: #SecretsDefaults

	// OpenAPIv3-compatible schema defining the structure of the Secrets spec
	spec: close({secrets: [secretName=string]: schemas.#SecretSchema & {name: string | *secretName}})
}

#Secrets: component.#Component & {

	#resources: {(#SecretsResource.metadata.fqn): #SecretsResource}
}

#SecretsDefaults: {
	type: string | *"Opaque"
}
