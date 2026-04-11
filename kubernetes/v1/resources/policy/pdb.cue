package policy

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// PodDisruptionBudget Resource Definition
/////////////////////////////////////////////////////////////////

// #PodDisruptionBudgetResource defines a native Kubernetes PodDisruptionBudget as an OPM resource.
// Use this to limit voluntary disruptions during cluster maintenance or rolling updates.
#PodDisruptionBudgetResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/policy"
		version:     "v1"
		name:        "poddisruptionbudget"
		description: "A native Kubernetes PodDisruptionBudget resource"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	#defaults: #PodDisruptionBudgetDefaults

	spec: close({poddisruptionbudget: schemas.#PodDisruptionBudgetSchema})
}

#PodDisruptionBudget: component.#Component & {
	#resources: {(#PodDisruptionBudgetResource.metadata.fqn): #PodDisruptionBudgetResource}
}

#PodDisruptionBudgetDefaults: schemas.#PodDisruptionBudgetSchema & {}
