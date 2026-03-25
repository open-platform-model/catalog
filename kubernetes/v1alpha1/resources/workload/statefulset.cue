package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// StatefulSet Resource Definition
/////////////////////////////////////////////////////////////////

// #StatefulSetResource defines a native Kubernetes StatefulSet as an OPM resource.
// Use this when you need direct control over the StatefulSet spec, e.g. for
// stateful workloads requiring stable network identities or persistent storage.
#StatefulSetResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/workload"
		version:     "v1"
		name:        "statefulset"
		description: "A native Kubernetes StatefulSet resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #StatefulSetDefaults

	spec: close({statefulset: schemas.#StatefulSetSchema})
}

#StatefulSetComponent: component.#Component & {
	#resources: {(#StatefulSetResource.metadata.fqn): #StatefulSetResource}
}

#StatefulSetDefaults: schemas.#StatefulSetSchema & {}
