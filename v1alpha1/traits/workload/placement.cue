package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Placement Trait Definition
/////////////////////////////////////////////////////////////////

#PlacementTrait: core.#Trait & {
	metadata: {
		cueModulePath: "opmodel.dev/traits/workload@v1"
		name:          "placement"
		description:   "Workload placement intent across failure domains"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #PlacementDefaults

	spec: close({placement: schemas.#PlacementSchema})
}

#Placement: core.#Component & {
	#traits: {(#PlacementTrait.metadata.fqn): #PlacementTrait}
}

#PlacementDefaults: schemas.#PlacementSchema & {
	spreadAcross: "zones"
}
