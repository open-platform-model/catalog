package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Sizing Trait Definition
/////////////////////////////////////////////////////////////////

#SizingTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "sizing"
		description: "A trait to specify compute sizing for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for sizing trait
	#defaults: #SizingDefaults

	#spec: sizing: schemas.#SizingSchema
})

#Sizing: close(core.#Component & {
	#traits: {(#SizingTrait.metadata.fqn): #SizingTrait}
})

#SizingDefaults: close(schemas.#SizingSchema & {
	cpu?: schemas.#SizingSchema.cpu & {
		request!: (number | string) | *"100m"
	}
	memory?: schemas.#SizingSchema.memory & {
		request!: (number | string) | *"128Mi"
	}
})
