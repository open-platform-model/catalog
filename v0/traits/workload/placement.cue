package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Placement Trait Definition
/////////////////////////////////////////////////////////////////

#PlacementTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "placement"
		description: "Workload placement intent across failure domains"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #PlacementDefaults

	#spec: placement: schemas.#PlacementSchema
}

#Placement: core.#Component & {
	#traits: {(#PlacementTrait.metadata.fqn): #PlacementTrait}
}

#PlacementDefaults: schemas.#PlacementSchema & {
	spreadAcross: "zones"
}
