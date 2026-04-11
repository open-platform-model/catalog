@if(test)

package transformers

// Test: minimal Role with required fields
_testRoleMinimal: (#RoleTransformer.#transform & {
	#component: {
		metadata: name: "app-role"
		spec: role: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-role"}).out
}).output & {
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "my-release-app-role"
		namespace: "default"
	}
}
