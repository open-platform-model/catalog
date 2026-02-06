package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// ResourceLimit Trait Definition
/////////////////////////////////////////////////////////////////

#ResourceLimitTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "resource-limit"
		description: "A trait to specify resource limits for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for resource limit trait
	#defaults: #ResourceLimitDefaults

	#spec: resourceLimit: schemas.#ResourceLimitSchema
})

#ResourceLimit: close(core.#Component & {
	#traits: {(#ResourceLimitTrait.metadata.fqn): #ResourceLimitTrait}
})

#ResourceLimitDefaults: close(schemas.#ResourceLimitSchema & {
	cpu?: schemas.#ResourceLimitSchema.cpu & {
		request!: string | *"100m"
	}
	memory?: schemas.#ResourceLimitSchema.memory & {
		request!: string | *"128Mi"
	}
})
