package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// DisruptionBudget Trait Definition
/////////////////////////////////////////////////////////////////

#DisruptionBudgetTrait: core.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/traits/workload"
		version:     "v1"
		name:        "disruption-budget"
		description: "Availability constraints during voluntary disruptions"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #DisruptionBudgetDefaults

	spec: close({disruptionBudget: schemas.#DisruptionBudgetSchema})
}

#DisruptionBudget: core.#Component & {
	#traits: {(#DisruptionBudgetTrait.metadata.fqn): #DisruptionBudgetTrait}
}

#DisruptionBudgetDefaults: schemas.#DisruptionBudgetSchema & {
	maxUnavailable: 1
}
