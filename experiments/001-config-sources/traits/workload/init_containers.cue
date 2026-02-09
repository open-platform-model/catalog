package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// InitContainers Trait Definition
/////////////////////////////////////////////////////////////////

#InitContainersTrait: close(core.#Trait & {
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
})

#InitContainers: close(core.#Component & {
	#traits: {(#InitContainersTrait.metadata.fqn): #InitContainersTrait}
})

#InitContainersDefaults: schemas.#InitContainersSchema & []
