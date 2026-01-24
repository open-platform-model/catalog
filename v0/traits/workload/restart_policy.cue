package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// RestartPolicy Trait Definition
/////////////////////////////////////////////////////////////////

#RestartPolicyTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v0"
		name:        "RestartPolicy"
		description: "A trait to specify the restart policy for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for restart policy trait
	#defaults: #RestartPolicyDefaults

	#spec: restartPolicy: schemas.#RestartPolicySchema
})

#RestartPolicy: close(core.#ComponentDefinition & {
	#traits: {(#RestartPolicyTrait.metadata.fqn): #RestartPolicyTrait}
})

#RestartPolicyDefaults: schemas.#RestartPolicySchema & "Always"
