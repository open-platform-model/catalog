package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	we "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/workloadentry/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// WorkloadEntry Resource Definition
/////////////////////////////////////////////////////////////////

#WorkloadEntryResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "workload-entry"
		description: "An Istio WorkloadEntry resource for enrolling non-Kubernetes workloads in the mesh"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #WorkloadEntryDefaults

	spec: close({workloadEntry: {
		metadata?: _#metadata
		spec?:     we.#WorkloadEntrySpec
	}})
}

#WorkloadEntry: component.#Component & {
	#resources: {(#WorkloadEntryResource.metadata.fqn): #WorkloadEntryResource}
}

#WorkloadEntryDefaults: {
	metadata?: _#metadata
	spec?:     we.#WorkloadEntrySpec
}
