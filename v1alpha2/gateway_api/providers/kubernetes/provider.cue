package kubernetes

import (
	provider       "opmodel.dev/opm/core/provider@v1"
	gw_transformers "opmodel.dev/gateway_api/providers/kubernetes/transformers"
)

// GatewayAPIKubernetesProvider transforms Gateway API components to Kubernetes native resources
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms Gateway API components to Kubernetes native resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	// Transformer registry - maps transformer FQNs to transformer definitions
	#transformers: {
		// Gateway API infrastructure transformers (resource-based)
		(gw_transformers.#GatewayTransformer.metadata.fqn):              gw_transformers.#GatewayTransformer
		(gw_transformers.#GatewayClassTransformer.metadata.fqn):         gw_transformers.#GatewayClassTransformer
		(gw_transformers.#ReferenceGrantTransformer.metadata.fqn):       gw_transformers.#ReferenceGrantTransformer
		(gw_transformers.#BackendTrafficPolicyTransformer.metadata.fqn): gw_transformers.#BackendTrafficPolicyTransformer

		// Gateway API route transformers (trait-based)
		(gw_transformers.#HttpRouteTransformer.metadata.fqn): gw_transformers.#HttpRouteTransformer
		(gw_transformers.#GrpcRouteTransformer.metadata.fqn): gw_transformers.#GrpcRouteTransformer
		(gw_transformers.#TcpRouteTransformer.metadata.fqn):  gw_transformers.#TcpRouteTransformer
		(gw_transformers.#TlsRouteTransformer.metadata.fqn):  gw_transformers.#TlsRouteTransformer
	}
}
