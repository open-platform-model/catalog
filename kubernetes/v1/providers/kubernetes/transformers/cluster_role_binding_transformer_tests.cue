@if(test)

package transformers

// Test: minimal ClusterRoleBinding — cluster-scoped, no namespace in output
_testClusterRoleBindingMinimal: (#ClusterRoleBindingTransformer.#transform & {
	#component: {
		metadata: name: "app-binding"
		spec: clusterrolebinding: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-binding"}).out
}).output & {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: name: "my-release-app-binding"
}
