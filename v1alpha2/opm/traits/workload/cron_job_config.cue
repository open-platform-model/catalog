package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// CronJobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#CronJobConfigTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
		version:     "v1"
		name:        "cron-job-config"
		description: "A trait to configure CronJob-specific settings for scheduled task workloads"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #CronJobConfigDefaults

	spec: close({cronJobConfig: schemas.#CronJobConfigSchema})
}

#CronJobConfig: component.#Component & {
	#traits: {(#CronJobConfigTrait.metadata.fqn): #CronJobConfigTrait}
}

#CronJobConfigDefaults: schemas.#CronJobConfigSchema & {
	concurrencyPolicy:          "Allow"
	successfulJobsHistoryLimit: 3
	failedJobsHistoryLimit:     1
}
