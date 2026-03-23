package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// UpdateStrategy Trait Definition
/////////////////////////////////////////////////////////////////

#UpdateStrategyTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
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

#UpdateStrategy: component.#Component & {
	#traits: {(#UpdateStrategyTrait.metadata.fqn): #UpdateStrategyTrait}
}

#UpdateStrategyDefaults: schemas.#UpdateStrategySchema & {
	type: "RollingUpdate"
	rollingUpdate: {
		maxUnavailable: 1
		maxSurge:       1
	}
}
