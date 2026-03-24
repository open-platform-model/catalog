package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Placement Trait Definition
/////////////////////////////////////////////////////////////////

#PlacementTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/workload"
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
