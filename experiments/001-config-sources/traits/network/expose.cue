package network

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// Expose Trait Definition
/////////////////////////////////////////////////////////////////

#ExposeTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/network@v0"
		name:        "expose"
		description: "A trait to expose a workload via a service"
		labels: {
			// "core.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource] // Full CUE reference (not FQN string)

	// Default values for expose trait
	#defaults: #ExposeDefaults

	#spec: expose: schemas.#ExposeSchema
})

#Expose: close(core.#Component & {
	#traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
})

#ExposeDefaults: close(schemas.#ExposeSchema & {
	type: "ClusterIP"
})
