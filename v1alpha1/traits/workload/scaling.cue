package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Scaling Trait Definition
/////////////////////////////////////////////////////////////////

#ScalingTrait: core.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/traits/workload"
		version:     "v1"
		name:        "scaling"
		description: "A trait to specify scaling behavior for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #ScalingDefaults

	spec: close({scaling: schemas.#ScalingSchema})
}

#Scaling: core.#Component & {
	#traits: {(#ScalingTrait.metadata.fqn): #ScalingTrait}
}

#ScalingDefaults: schemas.#ScalingSchema
