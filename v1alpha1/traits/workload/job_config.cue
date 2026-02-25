package workload

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// JobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#JobConfigTrait: core.#Trait & {
	metadata: {
		cueModulePath: "opmodel.dev/traits/workload@v1"
		name:          "job-config"
		description:   "A trait to configure Job-specific settings for task workloads"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #JobConfigDefaults

	spec: close({jobConfig: schemas.#JobConfigSchema})
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
