package config

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
)

/////////////////////////////////////////////////////////////////
//// ConfigMaps Resource Definition
/////////////////////////////////////////////////////////////////

#ConfigMapsResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/config@v0"
		name:        "config-maps"
		description: "A ConfigMap definition for external configuration"
		labels: {}
		annotations: {
			"transformer.opmodel.dev/list-output": true
		}
	}

	// Default values for ConfigMaps resource
	#defaults: #ConfigMapsDefaults

	// OpenAPIv3-compatible schema defining the structure of the ConfigMaps spec
	#spec: configMaps: [name=string]: schemas.#ConfigMapSchema
})

#ConfigMaps: close(core.#Component & {
	#resources: {(#ConfigMapsResource.metadata.fqn): #ConfigMapsResource}
})

#ConfigMapsDefaults: close(schemas.#ConfigMapSchema & {})
