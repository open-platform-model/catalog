package config

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ConfigMaps Resource Definition
/////////////////////////////////////////////////////////////////

#ConfigMapsResource: core.#Resource & {
	metadata: {
		modulePath: "opmodel.dev/resources/config@v1"
		name:          "config-maps"
		description:   "A ConfigMap definition for external configuration"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	// Default values for ConfigMaps resource
	#defaults: #ConfigMapsDefaults

	// OpenAPIv3-compatible schema defining the structure of the ConfigMaps spec
	spec: close({configMaps: [name=string]: schemas.#ConfigMapSchema})
}

#ConfigMaps: core.#Component & {
	metadata: annotations: {
		"transformer.opmodel.dev/list-output": true
	}

	#resources: {(#ConfigMapsResource.metadata.fqn): #ConfigMapsResource}
}

#ConfigMapsDefaults: schemas.#ConfigMapSchema & {}
