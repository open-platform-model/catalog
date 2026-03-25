@if(test)

package transformers

// Test: minimal ClusterRole — cluster-scoped, no namespace in output
_testClusterRoleMinimal: (#ClusterRoleTransformer.#transform & {
	#component: {
		metadata: name: "app-reader"
		spec: clusterrole: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-reader"}).out
}).output & {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: name: "my-release-app-reader"
}
