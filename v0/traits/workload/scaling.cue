package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// Scaling Trait Definition
/////////////////////////////////////////////////////////////////

#ScalingTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "scaling"
		description: "A trait to specify scaling behavior for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource] // Full CUE reference (not FQN string)

	// Default values for scaling trait
	#defaults: #ScalingDefaults

	#spec: scaling: schemas.#ScalingSchema
}

#Scaling: core.#Component & {
	#traits: {(#ScalingTrait.metadata.fqn): #ScalingTrait}
}

#ScalingDefaults: schemas.#ScalingSchema
