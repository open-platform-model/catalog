package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// Container Resource Definition
/////////////////////////////////////////////////////////////////

#ContainerResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/workload@v0"
		name:        "container"
		description: "A container definition for workloads"
		labels: {
			// "core.opmodel.dev/category": "workload"
		}
	}

	// Default values for container resource
	#defaults: #ContainerDefaults

	// OpenAPIv3-compatible schema defining the structure of the container spec
	#spec: container: schemas.#ContainerSchema
})

#Container: close(core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type"!: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
		...
	}

	#resources: {(#ContainerResource.metadata.fqn): #ContainerResource}
})

#ContainerDefaults: close(schemas.#ContainerSchema & {
	// Image pull policy
	imagePullPolicy: schemas.#ContainerSchema.imagePullPolicy | *"IfNotPresent"
})
