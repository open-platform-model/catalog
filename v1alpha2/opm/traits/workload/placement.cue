package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Placement Trait Definition
/////////////////////////////////////////////////////////////////

#PlacementTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
		version:     "v1"
		name:        "placement"
		description: "Workload placement intent across failure domains"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #PlacementDefaults

	spec: close({placement: schemas.#PlacementSchema})
}

#Placement: component.#Component & {
	#traits: {(#PlacementTrait.metadata.fqn): #PlacementTrait}
}

#PlacementDefaults: schemas.#PlacementSchema & {
	spreadAcross: "zones"
}
