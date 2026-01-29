package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// SidecarContainers Trait Definition
/////////////////////////////////////////////////////////////////

#SidecarContainersTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "SidecarContainers"
		description: "A trait to specify sidecar containers for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for sidecar containers trait
	#defaults: #SidecarContainersDefaults

	#spec: sidecarContainers: schemas.#SidecarContainersSchema
})

#SidecarContainers: close(core.#Component & {
	#traits: {(#SidecarContainersTrait.metadata.fqn): #SidecarContainersTrait}
})

#SidecarContainersDefaults: schemas.#SidecarContainersSchema & []
