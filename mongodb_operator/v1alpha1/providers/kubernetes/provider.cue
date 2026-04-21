package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	mdb_transformers "opmodel.dev/mongodb_operator/v1alpha1/providers/kubernetes/transformers"
)

// MongoDBOperatorKubernetesProvider transforms MongoDB Community Operator components
// to Kubernetes native resources (mongodbcommunity.mongodb.com/v1 CRs —
// pure passthrough with OPM context applied).
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms MongoDB operator components to Kubernetes native resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	#transformers: {
		(mdb_transformers.#MongoDBCommunityTransformer.metadata.fqn): mdb_transformers.#MongoDBCommunityTransformer
	}
}
