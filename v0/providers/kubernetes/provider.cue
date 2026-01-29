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
		"transformer.opmodel.dev/workload@v0#DeploymentTransformer":  k8s_transformers.#DeploymentTransformer
		"transformer.opmodel.dev/workload@v0#StatefulSetTransformer": k8s_transformers.#StatefulSetTransformer
		"transformer.opmodel.dev/workload@v0#DaemonSetTransformer":   k8s_transformers.#DaemonSetTransformer
		"transformer.opmodel.dev/workload@v0#JobTransformer":         k8s_transformers.#JobTransformer
		"transformer.opmodel.dev/workload@v0#CronJobTransformer":     k8s_transformers.#CronJobTransformer
		"transformer.opmodel.dev/network@v0#ServiceTransformer":      k8s_transformers.#ServiceTransformer
		"transformer.opmodel.dev/storage@v0#PVCTransformer":          k8s_transformers.#PVCTransformer
	}
}
