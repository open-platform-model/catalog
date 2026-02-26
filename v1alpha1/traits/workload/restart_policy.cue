package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// RestartPolicy Trait Definition
/////////////////////////////////////////////////////////////////

#RestartPolicyTrait: core.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/traits/workload"
		version:     "v1"
		name:        "restart-policy"
		description: "A trait to specify the restart policy for a workload"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #RestartPolicyDefaults

	spec: close({restartPolicy: schemas.#RestartPolicySchema})
}

#RestartPolicy: core.#Component & {
	#traits: {(#RestartPolicyTrait.metadata.fqn): #RestartPolicyTrait}
}

#RestartPolicyDefaults: schemas.#RestartPolicySchema & {"Always"}
