package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// Container Resource Definition
/////////////////////////////////////////////////////////////////

#ContainerResource: close(core.#ResourceDefinition & {
	metadata: {
		apiVersion:  "opm.dev/resources/workload@v0"
		name:        "Container"
		description: "A container definition for workloads"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	// Default values for container resource
	#defaults: #ContainerDefaults

	// OpenAPIv3-compatible schema defining the structure of the container spec
	#spec: container: schemas.#ContainerSchema
})

#Container: close(core.#ComponentDefinition & {
	metadata: labels: {
		"core.opm.dev/workload-type"!: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
		...
	}

	#resources: {(#ContainerResource.metadata.fqn): #ContainerResource}
})

#ContainerDefaults: close(schemas.#ContainerSchema & {
	// Image pull policy
	imagePullPolicy: schemas.#ContainerSchema.imagePullPolicy | *"IfNotPresent"
})
