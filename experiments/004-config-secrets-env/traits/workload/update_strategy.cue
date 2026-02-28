package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// UpdateStrategy Trait Definition
/////////////////////////////////////////////////////////////////

#UpdateStrategyTrait: core.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/traits/workload"
		version:     "v1"
		name:        "update-strategy"
		description: "A trait to specify the update strategy for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #UpdateStrategyDefaults

	spec: close({updateStrategy: schemas.#UpdateStrategySchema})
}

#UpdateStrategy: core.#Component & {
	#traits: {(#UpdateStrategyTrait.metadata.fqn): #UpdateStrategyTrait}
}

#UpdateStrategyDefaults: schemas.#UpdateStrategySchema & {
	type: "RollingUpdate"
	rollingUpdate: {
		maxUnavailable: 1
		maxSurge:       1
	}
}
