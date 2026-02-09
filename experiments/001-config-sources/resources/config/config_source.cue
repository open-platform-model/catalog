package config

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
)

/////////////////////////////////////////////////////////////////
//// ConfigSource Resource Definition
/////////////////////////////////////////////////////////////////

#ConfigSourceResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/config@v0"
		name:        "config-sources"
		description: "Named configuration sources for workloads"
		labels: {}
	}

	#defaults: #ConfigSourceDefaults

	#spec: configSources: [sourceName=string]: schemas.#ConfigSourceSchema
})

#ConfigSources: close(core.#Component & {
	#resources: {(#ConfigSourceResource.metadata.fqn): #ConfigSourceResource}
})

#ConfigSourceDefaults: close(schemas.#ConfigSourceSchema & {
	type: "config"
	data: {}
})
