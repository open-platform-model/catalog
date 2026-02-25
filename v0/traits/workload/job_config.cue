package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// JobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#JobConfigTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "job-config"
		description: "A trait to configure Job-specific settings for task workloads"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for job config trait
	#defaults: #JobConfigDefaults

	#spec: jobConfig: schemas.#JobConfigSchema
}

#JobConfig: core.#Component & {
	#traits: {(#JobConfigTrait.metadata.fqn): #JobConfigTrait}
}

#JobConfigDefaults: schemas.#JobConfigSchema & {
	completions:             1
	parallelism:             1
	backoffLimit:            6
	activeDeadlineSeconds:   300
	ttlSecondsAfterFinished: 100
}
