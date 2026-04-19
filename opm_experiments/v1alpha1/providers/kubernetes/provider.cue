package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	exp_transformers "opmodel.dev/opm_experiments/v1alpha1/providers/kubernetes/transformers"
)

// #Provider registers the experimental Kubernetes transformers that consume
// opm_experiments directives and traits.
//
// Stability: experimental. Definitions here may change or disappear; see
// opm_experiments/v1alpha1/README.md for graduation criteria.
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Experimental transformers consuming opm_experiments directives and traits"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":        "kubernetes"
			"core.opmodel.dev/platform":      "container-orchestrator"
			"provider.opmodel.dev/stability": "experimental"
		}
	}

	#transformers: {
		(exp_transformers.#K8upScheduleTransformer.metadata.fqn):      exp_transformers.#K8upScheduleTransformer
		(exp_transformers.#K8upPreBackupHookTransformer.metadata.fqn): exp_transformers.#K8upPreBackupHookTransformer
	}
}
