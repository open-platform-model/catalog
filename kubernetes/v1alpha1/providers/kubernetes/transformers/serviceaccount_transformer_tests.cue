@if(test)

package transformers

// Test: minimal ServiceAccount with required fields
_testServiceAccountMinimal: (#ServiceAccountTransformer.#transform & {
	#component: {
		metadata: name: "app"
		spec: serviceaccount: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app"}).out
}).output & {
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "my-release-app"
		namespace: "default"
	}
}
