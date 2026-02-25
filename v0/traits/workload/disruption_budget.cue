package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// DisruptionBudget Trait Definition
/////////////////////////////////////////////////////////////////

#DisruptionBudgetTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "disruption-budget"
		description: "Availability constraints during voluntary disruptions"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #DisruptionBudgetDefaults

	#spec: disruptionBudget: schemas.#DisruptionBudgetSchema
}

#DisruptionBudget: core.#Component & {
	#traits: {(#DisruptionBudgetTrait.metadata.fqn): #DisruptionBudgetTrait}
}

#DisruptionBudgetDefaults: schemas.#DisruptionBudgetSchema & {
	maxUnavailable: 1
}
