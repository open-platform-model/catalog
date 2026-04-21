package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	wg "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/workloadgroup/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// WorkloadGroup Resource Definition
/////////////////////////////////////////////////////////////////

#WorkloadGroupResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "workload-group"
		description: "An Istio WorkloadGroup resource — template for groups of non-Kubernetes workloads"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #WorkloadGroupDefaults

	spec: close({workloadGroup: {
		metadata?: _#metadata
		spec?:     wg.#WorkloadGroupSpec
	}})
}

#WorkloadGroup: component.#Component & {
	#resources: {(#WorkloadGroupResource.metadata.fqn): #WorkloadGroupResource}
}

#WorkloadGroupDefaults: {
	metadata?: _#metadata
	spec?:     wg.#WorkloadGroupSpec
}
