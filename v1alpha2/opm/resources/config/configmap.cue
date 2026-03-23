package config

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ConfigMaps Resource Definition
/////////////////////////////////////////////////////////////////

#ConfigMapsResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/resources/config"
		version:     "v1"
		name:        "config-maps"
		description: "A ConfigMap definition for external configuration"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	// Default values for ConfigMaps resource
	#defaults: #ConfigMapsDefaults

	// OpenAPIv3-compatible schema defining the structure of the ConfigMaps spec
	spec: close({configMaps: [cmName=string]: schemas.#ConfigMapSchema & {name: string | *cmName}})
}

#ConfigMaps: component.#Component & {

	#resources: {(#ConfigMapsResource.metadata.fqn): #ConfigMapsResource}
}

#ConfigMapsDefaults: {}
