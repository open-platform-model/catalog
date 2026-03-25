@if(test)

package transformers

// Test: minimal Secret with required fields
_testSecretMinimal: (#SecretTransformer.#transform & {
	#component: {
		metadata: name: "app-secret"
		spec: secret: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-secret"}).out
}).output & {
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "my-release-app-secret"
		namespace: "default"
	}
}
