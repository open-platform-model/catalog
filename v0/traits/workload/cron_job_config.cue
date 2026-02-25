package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// CronJobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#CronJobConfigTrait: core.#Trait & {
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
}

#CronJobConfig: core.#Component & {
	#traits: {(#CronJobConfigTrait.metadata.fqn): #CronJobConfigTrait}
}

#CronJobConfigDefaults: schemas.#CronJobConfigSchema & {
	concurrencyPolicy:          "Allow"
	successfulJobsHistoryLimit: 3
	failedJobsHistoryLimit:     1
}
