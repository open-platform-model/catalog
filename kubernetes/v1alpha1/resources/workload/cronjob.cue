package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// CronJob Resource Definition
/////////////////////////////////////////////////////////////////

// #CronJobResource defines a native Kubernetes CronJob as an OPM resource.
// Use this for scheduled recurring tasks expressed as cron expressions.
#CronJobResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/workload"
		version:     "v1"
		name:        "cronjob"
		description: "A native Kubernetes CronJob resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #CronJobDefaults

	spec: close({cronjob: schemas.#CronJobSchema})
}

#CronJobComponent: component.#Component & {
	#resources: {(#CronJobResource.metadata.fqn): #CronJobResource}
}

#CronJobDefaults: schemas.#CronJobSchema & {}
