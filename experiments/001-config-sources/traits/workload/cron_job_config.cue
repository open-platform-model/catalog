package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// CronJobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#CronJobConfigTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "cron-job-config"
		description: "A trait to configure CronJob-specific settings for scheduled task workloads"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for cron job config trait
	#defaults: #CronJobConfigDefaults

	#spec: cronJobConfig: schemas.#CronJobConfigSchema
})

#CronJobConfig: close(core.#Component & {
	#traits: {(#CronJobConfigTrait.metadata.fqn): #CronJobConfigTrait}
})

#CronJobConfigDefaults: close(schemas.#CronJobConfigSchema & {
	concurrencyPolicy:          "Allow"
	successfulJobsHistoryLimit: 3
	failedJobsHistoryLimit:     1
})
