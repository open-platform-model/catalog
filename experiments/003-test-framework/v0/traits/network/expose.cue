package network

import (
	core "experiments.dev/test-framework/v0/core"
	schemas "experiments.dev/test-framework/v0/schemas"
	workload_resources "experiments.dev/test-framework/v0/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// Expose Trait Definition
/////////////////////////////////////////////////////////////////

#ExposeTrait: core.#Trait & {
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
}

#Expose: core.#Component & {
	#traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
}

#ExposeDefaults: schemas.#ExposeSchema & {
	type: "ClusterIP"
}
