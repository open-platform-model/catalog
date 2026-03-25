package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// HostPID Trait Definition
////
//// Enables hostPID: true on the pod spec, sharing the node's
//// PID namespace. Required for workloads that must observe or
//// signal host processes (e.g. intel_gpu_top process-level GPU
//// metrics collection).
/////////////////////////////////////////////////////////////////

#HostPIDTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/security"
		version:     "v1"
		name:        "host-pid"
		description: "Share the node's PID namespace (hostPID: true)"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: false

	spec: close({hostPid: bool})
}

#HostPID: component.#Component & {
	#traits: {(#HostPIDTrait.metadata.fqn): #HostPIDTrait}
}
