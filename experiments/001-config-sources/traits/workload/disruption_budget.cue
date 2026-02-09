package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// DisruptionBudget Trait Definition
/////////////////////////////////////////////////////////////////

#DisruptionBudgetTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "disruption-budget"
		description: "Availability constraints during voluntary disruptions"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #DisruptionBudgetDefaults

	#spec: disruptionBudget: schemas.#DisruptionBudgetSchema
})

#DisruptionBudget: close(core.#Component & {
	#traits: {(#DisruptionBudgetTrait.metadata.fqn): #DisruptionBudgetTrait}
})

#DisruptionBudgetDefaults: schemas.#DisruptionBudgetSchema & {
	maxUnavailable: 1
}
