package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// RestartPolicy Trait Definition
/////////////////////////////////////////////////////////////////

#RestartPolicyTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "restart-policy"
		description: "A trait to specify the restart policy for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for restart policy trait
	#defaults: #RestartPolicyDefaults

	#spec: restartPolicy: schemas.#RestartPolicySchema
}

#RestartPolicy: core.#Component & {
	#traits: {(#RestartPolicyTrait.metadata.fqn): #RestartPolicyTrait}
}

#RestartPolicyDefaults: schemas.#RestartPolicySchema & "Always"
