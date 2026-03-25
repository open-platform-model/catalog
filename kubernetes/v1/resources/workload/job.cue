package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Job Resource Definition
/////////////////////////////////////////////////////////////////

// #JobResource defines a native Kubernetes Job as an OPM resource.
// Use this for batch or one-off tasks that run to completion.
#JobResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/workload"
		version:     "v1"
		name:        "job"
		description: "A native Kubernetes Job resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #JobDefaults

	spec: close({job: schemas.#JobSchema})
}

#Job: component.#Component & {
	#resources: {(#JobResource.metadata.fqn): #JobResource}
}

#JobDefaults: schemas.#JobSchema & {}
