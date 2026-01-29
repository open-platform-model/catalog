package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// RestartPolicy Trait Definition
/////////////////////////////////////////////////////////////////

#RestartPolicyTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "RestartPolicy"
		description: "A trait to specify the restart policy for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for restart policy trait
	#defaults: #RestartPolicyDefaults

	#spec: restartPolicy: schemas.#RestartPolicySchema
})

#RestartPolicy: close(core.#Component & {
	#traits: {(#RestartPolicyTrait.metadata.fqn): #RestartPolicyTrait}
})

#RestartPolicyDefaults: schemas.#RestartPolicySchema & "Always"
