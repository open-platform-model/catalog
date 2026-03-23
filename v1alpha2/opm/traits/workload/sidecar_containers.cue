package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// SidecarContainers Trait Definition
/////////////////////////////////////////////////////////////////

#SidecarContainersTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
		version:     "v1"
		name:        "sidecar-containers"
		description: "A trait to specify sidecar containers for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #SidecarContainersDefaults

	spec: close({sidecarContainers: [...schemas.#ContainerSchema]})
}

#SidecarContainers: component.#Component & {
	#traits: {(#SidecarContainersTrait.metadata.fqn): #SidecarContainersTrait}
}

#SidecarContainersDefaults: schemas.#ContainerSchema & {}
