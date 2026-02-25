package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// InitContainers Trait Definition
/////////////////////////////////////////////////////////////////

#InitContainersTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "init-containers"
		description: "A trait to specify init containers for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for init containers trait
	#defaults: #InitContainersDefaults

	#spec: initContainers: schemas.#InitContainersSchema
}

#InitContainers: core.#Component & {
	#traits: {(#InitContainersTrait.metadata.fqn): #InitContainersTrait}
}

#InitContainersDefaults: schemas.#InitContainersSchema & []
