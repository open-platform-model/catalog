package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// SidecarContainers Trait Definition
/////////////////////////////////////////////////////////////////

#SidecarContainersTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v0"
		name:        "SidecarContainers"
		description: "A trait to specify sidecar containers for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for sidecar containers trait
	#defaults: #SidecarContainersDefaults

	#spec: sidecarContainers: schemas.#SidecarContainersSchema
})

#SidecarContainers: close(core.#ComponentDefinition & {
	#traits: {(#SidecarContainersTrait.metadata.fqn): #SidecarContainersTrait}
})

#SidecarContainersDefaults: schemas.#SidecarContainersSchema & []
