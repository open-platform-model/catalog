package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// InitContainers Trait Definition
/////////////////////////////////////////////////////////////////

#InitContainersTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/workload"
		version:     "v1"
		name:        "init-containers"
		description: "A trait to specify init containers for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #InitContainersDefaults

	spec: close({initContainers: [...schemas.#ContainerSchema]})
}

#InitContainers: component.#Component & {
	#traits: {(#InitContainersTrait.metadata.fqn): #InitContainersTrait}
}

#InitContainersDefaults: schemas.#ContainerSchema & {}
