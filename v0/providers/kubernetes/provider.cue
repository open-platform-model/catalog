package kubernetes

import (
	core "opmodel.dev/core@v0"
	k8s_transformers "opmodel.dev/providers/kubernetes/transformers"
)

// KubernetesProvider transforms OPM components to Kubernetes native resources
#Provider: core.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms OPM components to Kubernetes native resources"
		version:     "1.0.0"
		minVersion:  "1.0.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	// Transformer registry - maps transformer FQNs to transformer definitions
	transformers: {
		(k8s_transformers.#DeploymentTransformer.metadata.fqn):  k8s_transformers.#DeploymentTransformer
		(k8s_transformers.#StatefulsetTransformer.metadata.fqn): k8s_transformers.#StatefulsetTransformer
		(k8s_transformers.#DaemonSetTransformer.metadata.fqn):   k8s_transformers.#DaemonSetTransformer
		(k8s_transformers.#JobTransformer.metadata.fqn):         k8s_transformers.#JobTransformer
		(k8s_transformers.#CronJobTransformer.metadata.fqn):     k8s_transformers.#CronJobTransformer
		(k8s_transformers.#ServiceTransformer.metadata.fqn):     k8s_transformers.#ServiceTransformer
		(k8s_transformers.#PVCTransformer.metadata.fqn):         k8s_transformers.#PVCTransformer
	}
}
