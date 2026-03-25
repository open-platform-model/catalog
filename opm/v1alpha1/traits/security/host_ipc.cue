package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// HostIPC Trait Definition
////
//// Enables hostIPC: true on the pod spec, sharing the node's
//// IPC namespace. Required for workloads that use shared
//// memory or IPC mechanisms with host processes.
/////////////////////////////////////////////////////////////////

#HostIPCTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/security"
		version:     "v1"
		name:        "host-ipc"
		description: "Share the node's IPC namespace (hostIPC: true)"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: false

	spec: close({hostIpc: bool})
}

#HostIPC: component.#Component & {
	#traits: {(#HostIPCTrait.metadata.fqn): #HostIPCTrait}
}
