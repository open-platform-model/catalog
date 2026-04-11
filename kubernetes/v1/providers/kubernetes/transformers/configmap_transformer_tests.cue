@if(test)

package transformers

// Test: minimal ConfigMap with required fields
_testConfigMapMinimal: (#ConfigMapTransformer.#transform & {
	#component: {
		metadata: name: "app-config"
		spec: configmap: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "app-config"}).out
}).output & {
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "my-release-app-config"
		namespace: "default"
	}
}
