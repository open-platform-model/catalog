package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	otel_transformers "opmodel.dev/otel_collector/v1alpha1/providers/kubernetes/transformers"
)

// OtelCollectorKubernetesProvider transforms OpenTelemetry operator components
// to Kubernetes native resources (opentelemetry.io CRs — passthrough with OPM context applied).
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms OTEL operator components to Kubernetes native resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	#transformers: {
		(otel_transformers.#CollectorTransformer.metadata.fqn):       otel_transformers.#CollectorTransformer
		(otel_transformers.#InstrumentationTransformer.metadata.fqn): otel_transformers.#InstrumentationTransformer
		(otel_transformers.#OpAMPBridgeTransformer.metadata.fqn):     otel_transformers.#OpAMPBridgeTransformer
	}
}
