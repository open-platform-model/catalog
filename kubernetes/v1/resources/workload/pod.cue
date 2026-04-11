package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Pod Resource Definition
/////////////////////////////////////////////////////////////////

// #PodResource defines a native Kubernetes Pod as an OPM resource.
// Use this for standalone pods; prefer Deployment or StatefulSet for
// production workloads that need scheduling guarantees.
#PodResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/workload"
		version:     "v1"
		name:        "pod"
		description: "A native Kubernetes Pod resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #PodDefaults

	spec: close({pod: schemas.#PodSchema})
}

#Pod: component.#Component & {
	#resources: {(#PodResource.metadata.fqn): #PodResource}
}

#PodDefaults: schemas.#PodSchema & {}
