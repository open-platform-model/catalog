// End-to-end test harness for RBAC resources (ServiceAccount + Role).
//
// Tests the full pipeline WITHOUT the CLI by manually wiring:
//   concrete component → transformer #transform → K8s output
//
// Run:
//   cue eval ./test/                          (from experiments/005-rbac-e2e/)
//   cue eval -e serviceAccount ./test/        (just the ServiceAccount)
//   cue eval -e nsRole ./test/                (just namespace-scoped Role + RoleBinding)
//   cue eval -e clusterRole ./test/           (just cluster-scoped ClusterRole + ClusterRoleBinding)
//
// Verification points:
//   1. serviceAccount.output
//      → K8s ServiceAccount with correct name, namespace, automountToken
//   2. nsRole.output
//      → "Role/pod-reader" + "RoleBinding/pod-reader" with rules, subjects, roleRef
//   3. clusterRole.output
//      → "ClusterRole/node-reader" + "ClusterRoleBinding/node-reader" (no namespace on role)
package test

import (
	core "opmodel.dev/core@v1"
	security_resources "opmodel.dev/resources/security@v1"
	transformers "opmodel.dev/providers/kubernetes/transformers@v1"
)

/////////////////////////////////////////////////////////////////
//// Test Data: ServiceAccount Component
/////////////////////////////////////////////////////////////////

_saComponent: security_resources.#ServiceAccount & {
	spec: serviceAccount: {
		name:           "deploy-bot"
		automountToken: true
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data: Namespace-scoped Role Component
/////////////////////////////////////////////////////////////////

_nsRoleComponent: security_resources.#Role & {
	spec: role: {
		name:  "pod-reader"
		scope: "namespace"
		rules: [{
			apiGroups: [""]
			resources: ["pods", "pods/log"]
			verbs: ["get", "list", "watch"]
		}, {
			apiGroups: ["apps"]
			resources: ["deployments"]
			verbs: ["get", "list"]
		}]
		subjects: [{
			name:           "deploy-bot"
			automountToken: true
		}]
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data: Cluster-scoped Role Component
/////////////////////////////////////////////////////////////////

_clusterRoleComponent: security_resources.#Role & {
	spec: role: {
		name:  "node-reader"
		scope: "cluster"
		rules: [{
			apiGroups: [""]
			resources: ["nodes"]
			verbs: ["get", "list", "watch"]
		}]
		subjects: [{
			name:           "deploy-bot"
			automountToken: true
		}, {
			name:           "monitor-sa"
			automountToken: false
		}]
	}
}

/////////////////////////////////////////////////////////////////
//// Transformer Context (minimal stub)
/////////////////////////////////////////////////////////////////

_ctx: core.#TransformerContext & {
	#moduleReleaseMetadata: {
		name:      "rbac-test"
		namespace: "test-ns"
		fqn:       "test/rbac-test"
		version:   "1.0.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: {
		name: "rbac-component"
	}
	name:      "rbac-test"
	namespace: "test-ns"
}

/////////////////////////////////////////////////////////////////
//// Transformer Invocations
/////////////////////////////////////////////////////////////////

// K8s ServiceAccount — validates name, namespace, automountToken
serviceAccount: (transformers.#ServiceAccountResourceTransformer.#transform & {
	#component: _saComponent
	#context:   _ctx
})

// K8s Role + RoleBinding — validates namespace-scoped RBAC
nsRole: (transformers.#RoleTransformer.#transform & {
	#component: _nsRoleComponent
	#context:   _ctx
})

// K8s ClusterRole + ClusterRoleBinding — validates cluster-scoped RBAC
clusterRole: (transformers.#RoleTransformer.#transform & {
	#component: _clusterRoleComponent
	#context:   _ctx
})
