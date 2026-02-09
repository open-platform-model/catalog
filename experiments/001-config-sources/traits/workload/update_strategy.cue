package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// UpdateStrategy Trait Definition
/////////////////////////////////////////////////////////////////

#UpdateStrategyTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "update-strategy"
		description: "A trait to specify the update strategy for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for update strategy trait
	#defaults: #UpdateStrategyDefaults

	#spec: updateStrategy: schemas.#UpdateStrategySchema
})

#UpdateStrategy: close(core.#Component & {
	#traits: {(#UpdateStrategyTrait.metadata.fqn): #UpdateStrategyTrait}
})

#UpdateStrategyDefaults: close(schemas.#UpdateStrategySchema & {
	type: "RollingUpdate"
	rollingUpdate: {
		maxUnavailable: 1
		maxSurge:       1
	}
})
