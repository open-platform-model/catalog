package network

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Expose Trait Definition
/////////////////////////////////////////////////////////////////

#ExposeTrait: core.#Trait & {
	metadata: {
		modulePath: "opmodel.dev/traits/network@v1"
		name:          "expose"
		description:   "A trait to expose a workload via a service"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource] // Full CUE reference (not FQN string)

	// Default values for expose trait
	#defaults: #ExposeDefaults

	spec: close({expose: schemas.#ExposeSchema})
}

#Expose: core.#Component & {
	#traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
}

#ExposeDefaults: schemas.#ExposeSchema & {
	type: "ClusterIP"
}
