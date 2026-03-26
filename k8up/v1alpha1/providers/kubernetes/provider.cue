package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	k8up_transformers "opmodel.dev/k8up/v1alpha1/providers/kubernetes/transformers"
)

// K8upKubernetesProvider transforms K8up backup components to Kubernetes native resources
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Pass-through transformers for native K8up backup resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	#transformers: {
		(k8up_transformers.#ScheduleTransformer.metadata.fqn):     k8up_transformers.#ScheduleTransformer
		(k8up_transformers.#PreBackupPodTransformer.metadata.fqn): k8up_transformers.#PreBackupPodTransformer
		(k8up_transformers.#BackupTransformer.metadata.fqn):       k8up_transformers.#BackupTransformer
		(k8up_transformers.#RestoreTransformer.metadata.fqn):      k8up_transformers.#RestoreTransformer
	}
}
