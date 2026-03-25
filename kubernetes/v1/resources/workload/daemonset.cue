package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// DaemonSet Resource Definition
/////////////////////////////////////////////////////////////////

// #DaemonSetResource defines a native Kubernetes DaemonSet as an OPM resource.
// Use this when you need to run a pod on every (or selected) node in the cluster.
#DaemonSetResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/workload"
		version:     "v1"
		name:        "daemonset"
		description: "A native Kubernetes DaemonSet resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #DaemonSetDefaults

	spec: close({daemonset: schemas.#DaemonSetSchema})
}

#DaemonSet: component.#Component & {
	#resources: {(#DaemonSetResource.metadata.fqn): #DaemonSetResource}
}

#DaemonSetDefaults: schemas.#DaemonSetSchema & {}
