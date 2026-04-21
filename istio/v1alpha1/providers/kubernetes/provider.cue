package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	istio_transformers "opmodel.dev/istio/v1alpha1/providers/kubernetes/transformers"
)

// IstioKubernetesProvider transforms Istio components to Kubernetes native CRs.
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Pass-through transformers for native Istio resources (networking, security, telemetry, extensions)"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	#transformers: {
		// networking.istio.io
		(istio_transformers.#VirtualServiceTransformer.metadata.fqn):  istio_transformers.#VirtualServiceTransformer
		(istio_transformers.#DestinationRuleTransformer.metadata.fqn): istio_transformers.#DestinationRuleTransformer
		(istio_transformers.#IstioGatewayTransformer.metadata.fqn):    istio_transformers.#IstioGatewayTransformer
		(istio_transformers.#SidecarTransformer.metadata.fqn):         istio_transformers.#SidecarTransformer
		(istio_transformers.#ServiceEntryTransformer.metadata.fqn):    istio_transformers.#ServiceEntryTransformer
		(istio_transformers.#WorkloadEntryTransformer.metadata.fqn):   istio_transformers.#WorkloadEntryTransformer
		(istio_transformers.#WorkloadGroupTransformer.metadata.fqn):   istio_transformers.#WorkloadGroupTransformer
		(istio_transformers.#EnvoyFilterTransformer.metadata.fqn):     istio_transformers.#EnvoyFilterTransformer
		(istio_transformers.#ProxyConfigTransformer.metadata.fqn):     istio_transformers.#ProxyConfigTransformer

		// security.istio.io
		(istio_transformers.#AuthorizationPolicyTransformer.metadata.fqn):   istio_transformers.#AuthorizationPolicyTransformer
		(istio_transformers.#PeerAuthenticationTransformer.metadata.fqn):    istio_transformers.#PeerAuthenticationTransformer
		(istio_transformers.#RequestAuthenticationTransformer.metadata.fqn): istio_transformers.#RequestAuthenticationTransformer

		// telemetry.istio.io
		(istio_transformers.#TelemetryTransformer.metadata.fqn): istio_transformers.#TelemetryTransformer

		// extensions.istio.io
		(istio_transformers.#WasmPluginTransformer.metadata.fqn): istio_transformers.#WasmPluginTransformer
	}
}
