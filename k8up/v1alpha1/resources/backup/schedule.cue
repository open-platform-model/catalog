package backup

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/k8up/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Schedule Resource Definition
/////////////////////////////////////////////////////////////////

#ScheduleResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/resources/backup"
		version:     "v1"
		name:        "schedule"
		description: "A K8up Schedule (recurring backup, check, and prune)"
		labels: {
			"resource.opmodel.dev/category": "backup"
		}
	}

	#defaults: #ScheduleDefaults

	spec: close({schedule: schemas.#ScheduleSchema})
}

#Schedule: component.#Component & {
	#resources: {(#ScheduleResource.metadata.fqn): #ScheduleResource}
}

#ScheduleDefaults: schemas.#ScheduleSchema
