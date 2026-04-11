package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// HostNetwork Trait Definition
////
//// Enables hostNetwork: true on the pod spec, sharing the node's
//// network namespace. Required for workloads that must bind to
//// host interfaces directly (e.g. MetalLB speaker for ARP/NDP).
/////////////////////////////////////////////////////////////////

#HostNetworkTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/network"
		version:     "v1"
		name:        "host-network"
		description: "Share the node's network namespace (hostNetwork: true)"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: false

	spec: close({hostNetwork: bool})
}

#HostNetwork: component.#Component & {
	#traits: {(#HostNetworkTrait.metadata.fqn): #HostNetworkTrait}
}
