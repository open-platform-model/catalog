@if(test)

package transformers

// Test: minimal Ingress with required fields
_testIngressMinimal: (#IngressTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: ingress: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "web"}).out
}).output & {
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "my-release-web"
		namespace: "default"
	}
}
