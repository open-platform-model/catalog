package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// JobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#JobConfigTrait: close(core.#Trait & {
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
})

#JobConfig: close(core.#Component & {
	#traits: {(#JobConfigTrait.metadata.fqn): #JobConfigTrait}
})

#JobConfigDefaults: close(schemas.#JobConfigSchema & {
	completions:             1
	parallelism:             1
	backoffLimit:            6
	activeDeadlineSeconds:   300
	ttlSecondsAfterFinished: 100
})
