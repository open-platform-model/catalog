package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Sizing Trait Definition
/////////////////////////////////////////////////////////////////

#SizingTrait: core.#Trait & {
	metadata: {
		cueModulePath: "opmodel.dev/traits/workload@v1"
		name:          "sizing"
		description:   "A trait to specify vertical sizing behavior for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #SizingDefaults

	spec: close({sizing: schemas.#SizingSchema})
}

#Sizing: core.#Component & {
	#traits: {(#SizingTrait.metadata.fqn): #SizingTrait}
}

#SizingDefaults: schemas.#SizingSchema
