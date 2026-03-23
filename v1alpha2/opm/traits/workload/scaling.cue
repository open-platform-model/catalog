package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Scaling Trait Definition
/////////////////////////////////////////////////////////////////

#ScalingTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
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

#Scaling: component.#Component & {
	#traits: {(#ScalingTrait.metadata.fqn): #ScalingTrait}
}

#ScalingDefaults: schemas.#ScalingSchema
