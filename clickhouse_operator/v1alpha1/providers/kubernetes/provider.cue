package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	chop_transformers "opmodel.dev/clickhouse_operator/v1alpha1/providers/kubernetes/transformers"
)

// ClickHouseOperatorKubernetesProvider transforms ClickHouse operator components
// to Kubernetes native resources (Altinity CRs — pure passthrough with OPM context applied).
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms ClickHouse operator components to Kubernetes native resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	#transformers: {
		(chop_transformers.#ClickHouseInstallationTransformer.metadata.fqn):          chop_transformers.#ClickHouseInstallationTransformer
		(chop_transformers.#ClickHouseInstallationTemplateTransformer.metadata.fqn):  chop_transformers.#ClickHouseInstallationTemplateTransformer
		(chop_transformers.#ClickHouseKeeperInstallationTransformer.metadata.fqn):    chop_transformers.#ClickHouseKeeperInstallationTransformer
		(chop_transformers.#ClickHouseOperatorConfigurationTransformer.metadata.fqn): chop_transformers.#ClickHouseOperatorConfigurationTransformer
	}
}
