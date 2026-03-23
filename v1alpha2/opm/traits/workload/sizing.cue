package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Sizing Trait Definition
/////////////////////////////////////////////////////////////////

#SizingTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
		version:     "v1"
		name:        "sizing"
		description: "A trait to specify vertical sizing behavior for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #SizingDefaults

	spec: close({sizing: schemas.#SizingSchema})
}

#Sizing: component.#Component & {
	#traits: {(#SizingTrait.metadata.fqn): #SizingTrait}
}

#SizingDefaults: schemas.#SizingSchema
