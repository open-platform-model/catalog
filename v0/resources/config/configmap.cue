package config

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// ConfigMaps Resource Definition
/////////////////////////////////////////////////////////////////

#ConfigMapsResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/config@v0"
		name:        "config-maps"
		description: "A ConfigMap definition for external configuration"
	}

	// Default values for ConfigMaps resource
	#defaults: #ConfigMapsDefaults

	// OpenAPIv3-compatible schema defining the structure of the ConfigMaps spec
	#spec: configMaps: [name=string]: schemas.#ConfigMapSchema
})

#ConfigMaps: close(core.#Component & {
	metadata: annotations: {
		"transformer.opmodel.dev/list-output": true
	}

	#resources: {(#ConfigMapsResource.metadata.fqn): #ConfigMapsResource}
})

#ConfigMapsDefaults: close(schemas.#ConfigMapSchema & {})
