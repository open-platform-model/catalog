package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// InitContainers Trait Definition
/////////////////////////////////////////////////////////////////

#InitContainersTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v0"
		name:        "InitContainers"
		description: "A trait to specify init containers for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for init containers trait
	#defaults: #InitContainersDefaults

	#spec: initContainers: schemas.#InitContainersSchema
})

#InitContainers: close(core.#ComponentDefinition & {
	#traits: {(#InitContainersTrait.metadata.fqn): #InitContainersTrait}
})

#InitContainersDefaults: schemas.#InitContainersSchema & []
