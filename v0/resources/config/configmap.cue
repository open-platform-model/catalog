package config

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// ConfigMap Resource Definition
/////////////////////////////////////////////////////////////////

#ConfigMapResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/config@v0"
		name:        "config-map"
		description: "A ConfigMap definition for external configuration"
		labels: {}
	}

	// Default values for ConfigMap resource
	#defaults: #ConfigMapDefaults

	// OpenAPIv3-compatible schema defining the structure of the ConfigMap spec
	#spec: configMap: schemas.#ConfigMapSchema
})

#ConfigMap: close(core.#Component & {
	#resources: {(#ConfigMapResource.metadata.fqn): #ConfigMapResource}
})

#ConfigMapDefaults: close(schemas.#ConfigMapSchema & {})
