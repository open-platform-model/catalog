package workload

import (
	core "opm.dev/core@v0"
)

// #WorkloadReady: Checks if a standard Kubernetes workload (Deployment, StatefulSet)
// has the expected number of ready replicas.
#WorkloadReady: core.#StatusProbe & {
	metadata: {
		apiVersion: "opm.dev/probes/workload@v0"
		name:       "WorkloadReady"
		description: "Checks if all replicas are ready"
	}

	#params: {
		// The name of the resource in the context.outputs map
		name: string
	}

	result: {
		let workload = context.outputs[#params.name]
		
		// Logic handles standard K8s status fields
		healthy: workload.status.readyReplicas == workload.spec.replicas
		
		message: "Workload '\(#params.name)' has \(workload.status.readyReplicas)/\(workload.spec.replicas) ready"
	}
}
