@if(test)

package transformers

// Test: minimal RoleBinding with required fields
_testRoleBindingMinimal: (#RoleBindingTransformer.#transform & {
	#component: {
		metadata: name: "app-binding"
		spec: rolebinding: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-binding"}).out
}).output & {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "my-release-app-binding"
		namespace: "default"
	}
}
