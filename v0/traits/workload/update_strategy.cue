package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// UpdateStrategy Trait Definition
/////////////////////////////////////////////////////////////////

#UpdateStrategyTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v0"
		name:        "UpdateStrategy"
		description: "A trait to specify the update strategy for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for update strategy trait
	#defaults: #UpdateStrategyDefaults

	#spec: updateStrategy: schemas.#UpdateStrategySchema
})

#UpdateStrategy: close(core.#ComponentDefinition & {
	#traits: {(#UpdateStrategyTrait.metadata.fqn): #UpdateStrategyTrait}
})

#UpdateStrategyDefaults: close(schemas.#UpdateStrategySchema & {
	type: "RollingUpdate"
	rollingUpdate: {
		maxUnavailable: 1
		maxSurge:       1
	}
})
