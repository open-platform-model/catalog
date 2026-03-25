@if(test)

package transformers

// Test: minimal Namespace — cluster-scoped, no namespace in output
_testNamespaceMinimal: (#NamespaceTransformer.#transform & {
	#component: {
		metadata: name: "team-a"
		spec: namespace: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "team-a"}).out
}).output & {
	apiVersion: "v1"
	kind:       "Namespace"
	metadata: name: "my-release-team-a"
}
