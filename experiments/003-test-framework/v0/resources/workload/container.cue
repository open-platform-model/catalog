package workload

import (
	core "experiments.dev/test-framework/v0/core"
	schemas "experiments.dev/test-framework/v0/schemas"
)

/////////////////////////////////////////////////////////////////
//// Container Resource Definition
/////////////////////////////////////////////////////////////////

#ContainerResource: core.#Resource & {
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
}

#Container: core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type"!: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
		...
	}

	#resources: {(#ContainerResource.metadata.fqn): #ContainerResource}
}

#ContainerDefaults: schemas.#ContainerSchema & {
	// Image pull policy
	imagePullPolicy: schemas.#ContainerSchema.imagePullPolicy | *"IfNotPresent"
}
