package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	cm_transformers "opmodel.dev/cert_manager/v1alpha1/providers/kubernetes/transformers"
)

// CertManagerKubernetesProvider transforms cert-manager components to Kubernetes native resources
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms cert-manager components to Kubernetes native resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	// Transformer registry - maps transformer FQNs to transformer definitions
	#transformers: {
		// cert-manager transformers (resource-based)
		(cm_transformers.#CertificateTransformer.metadata.fqn):   cm_transformers.#CertificateTransformer
		(cm_transformers.#IssuerTransformer.metadata.fqn):        cm_transformers.#IssuerTransformer
		(cm_transformers.#ClusterIssuerTransformer.metadata.fqn): cm_transformers.#ClusterIssuerTransformer
	}
}
