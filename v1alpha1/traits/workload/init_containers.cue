package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// InitContainers Trait Definition
/////////////////////////////////////////////////////////////////

#InitContainersTrait: core.#Trait & {
	metadata: {
		modulePath: "opmodel.dev/traits/workload@v1"
		name:          "init-containers"
		description:   "A trait to specify init containers for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #InitContainersDefaults

	spec: close({initContainers: [...schemas.#ContainerSchema]})
}

#InitContainers: core.#Component & {
	#traits: {(#InitContainersTrait.metadata.fqn): #InitContainersTrait}
}

#InitContainersDefaults: schemas.#ContainerSchema & {
}
