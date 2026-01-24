package kubernetes

import (
	core "opm.dev/core@v1"
	k8s_transformers "opm.dev/providers/kubernetes/transformers"
)

// KubernetesProvider transforms OPM components to Kubernetes native resources
#KubernetesProvider: core.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms OPM components to Kubernetes native resources"
		version:     "1.0.0"
		minVersion:  "1.0.0"

		labels: {
			"core.opm.dev/format":   "kubernetes"
			"core.opm.dev/platform": "container-orchestrator"
		}
	}

	// Transformer registry - maps transformer FQNs to transformer definitions
	transformers: {
		"transformer.opm.dev/workload@v1#DeploymentTransformer":  k8s_transformers.#DeploymentTransformer
		"transformer.opm.dev/workload@v1#StatefulSetTransformer": k8s_transformers.#StatefulSetTransformer
		"transformer.opm.dev/workload@v1#DaemonSetTransformer":   k8s_transformers.#DaemonSetTransformer
		"transformer.opm.dev/workload@v1#JobTransformer":         k8s_transformers.#JobTransformer
		"transformer.opm.dev/workload@v1#CronJobTransformer":     k8s_transformers.#CronJobTransformer
		"transformer.opm.dev/network@v1#ServiceTransformer":      k8s_transformers.#ServiceTransformer
		"transformer.opm.dev/storage@v1#PVCTransformer":          k8s_transformers.#PVCTransformer
	}
}
