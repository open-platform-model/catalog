package network

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Expose Trait Definition
/////////////////////////////////////////////////////////////////

#ExposeTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opm.dev/traits/networking@v0"
		name:        "Expose"
		description: "A trait to expose a workload via a service"
		labels: {
			// "core.opm.dev/category": "networking"
		}
	}

	appliesTo: [workload_resources.#ContainerResource] // Full CUE reference (not FQN string)

	// Default values for expose trait
	#defaults: #ExposeTraitDefaults

	#spec: expose: schemas.#ExposeSchema
})

#Expose: close(core.#Component & {
	#traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
})

#ExposeTraitDefaults: close(schemas.#ExposeSchema & {
	type: "ClusterIP"
})
