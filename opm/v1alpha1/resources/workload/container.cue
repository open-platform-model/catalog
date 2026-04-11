package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Container Resource Definition
/////////////////////////////////////////////////////////////////

#ContainerResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/resources/workload"
		version:     "v1"
		name:        "container"
		description: "A container definition for workloads"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	// Default values for container resource
	#defaults: #ContainerDefaults

	// OpenAPIv3-compatible schema defining the structure of the container spec
	spec: close({container: schemas.#ContainerSchema})
}

#Container: component.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type"!: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
	}

	#resources: {(#ContainerResource.metadata.fqn): #ContainerResource}
}

#ContainerDefaults: schemas.#ContainerSchema & {}
