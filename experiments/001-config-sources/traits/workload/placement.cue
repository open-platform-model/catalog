package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// Placement Trait Definition
/////////////////////////////////////////////////////////////////

#PlacementTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "placement"
		description: "Workload placement intent across failure domains"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #PlacementDefaults

	#spec: placement: schemas.#PlacementSchema
})

#Placement: close(core.#Component & {
	#traits: {(#PlacementTrait.metadata.fqn): #PlacementTrait}
})

#PlacementDefaults: close(schemas.#PlacementSchema & {
	spreadAcross: "zones"
})
