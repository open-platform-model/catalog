package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	k8s_transformers "opmodel.dev/kubernetes/v1alpha1/providers/kubernetes/transformers@v1"
)

// KubernetesNativeProvider registers pass-through transformers for native Kubernetes resources.
// This provider applies OPM context (name prefix, namespace, labels) to native K8s specs.
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes-native"
		description: "Pass-through transformers for native Kubernetes resources"
		version:     "0.1.0"
		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	// Transformer registry — maps transformer FQNs to transformer definitions
	#transformers: {
		// Workload transformers
		(k8s_transformers.#DeploymentTransformer.metadata.fqn):  k8s_transformers.#DeploymentTransformer
		(k8s_transformers.#StatefulSetTransformer.metadata.fqn): k8s_transformers.#StatefulSetTransformer
		(k8s_transformers.#DaemonSetTransformer.metadata.fqn):   k8s_transformers.#DaemonSetTransformer
		(k8s_transformers.#JobTransformer.metadata.fqn):         k8s_transformers.#JobTransformer
		(k8s_transformers.#CronJobTransformer.metadata.fqn):     k8s_transformers.#CronJobTransformer
		(k8s_transformers.#PodTransformer.metadata.fqn):         k8s_transformers.#PodTransformer

		// Config transformers
		(k8s_transformers.#ConfigMapTransformer.metadata.fqn): k8s_transformers.#ConfigMapTransformer
		(k8s_transformers.#SecretTransformer.metadata.fqn):    k8s_transformers.#SecretTransformer

		// Storage transformers
		(k8s_transformers.#PersistentVolumeClaimTransformer.metadata.fqn): k8s_transformers.#PersistentVolumeClaimTransformer
		(k8s_transformers.#PersistentVolumeTransformer.metadata.fqn):      k8s_transformers.#PersistentVolumeTransformer
		(k8s_transformers.#StorageClassTransformer.metadata.fqn):          k8s_transformers.#StorageClassTransformer

		// Network transformers
		(k8s_transformers.#ServiceTransformer.metadata.fqn):       k8s_transformers.#ServiceTransformer
		(k8s_transformers.#IngressTransformer.metadata.fqn):       k8s_transformers.#IngressTransformer
		(k8s_transformers.#IngressClassTransformer.metadata.fqn):  k8s_transformers.#IngressClassTransformer
		(k8s_transformers.#NetworkPolicyTransformer.metadata.fqn): k8s_transformers.#NetworkPolicyTransformer

		// RBAC transformers
		(k8s_transformers.#ServiceAccountTransformer.metadata.fqn):     k8s_transformers.#ServiceAccountTransformer
		(k8s_transformers.#RoleTransformer.metadata.fqn):               k8s_transformers.#RoleTransformer
		(k8s_transformers.#ClusterRoleTransformer.metadata.fqn):        k8s_transformers.#ClusterRoleTransformer
		(k8s_transformers.#RoleBindingTransformer.metadata.fqn):        k8s_transformers.#RoleBindingTransformer
		(k8s_transformers.#ClusterRoleBindingTransformer.metadata.fqn): k8s_transformers.#ClusterRoleBindingTransformer

		// Cluster transformers
		(k8s_transformers.#NamespaceTransformer.metadata.fqn): k8s_transformers.#NamespaceTransformer

		// Policy transformers
		(k8s_transformers.#HorizontalPodAutoscalerTransformer.metadata.fqn): k8s_transformers.#HorizontalPodAutoscalerTransformer
		(k8s_transformers.#PodDisruptionBudgetTransformer.metadata.fqn):     k8s_transformers.#PodDisruptionBudgetTransformer

		// Admission transformers
		(k8s_transformers.#ValidatingWebhookConfigurationTransformer.metadata.fqn): k8s_transformers.#ValidatingWebhookConfigurationTransformer
		(k8s_transformers.#MutatingWebhookConfigurationTransformer.metadata.fqn):   k8s_transformers.#MutatingWebhookConfigurationTransformer
	}
}
