package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// SidecarContainers Trait Definition
/////////////////////////////////////////////////////////////////

#SidecarContainersTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "sidecar-containers"
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
