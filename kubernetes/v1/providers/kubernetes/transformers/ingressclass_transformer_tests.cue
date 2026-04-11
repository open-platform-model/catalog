@if(test)

package transformers

// Test: minimal IngressClass — cluster-scoped, no namespace in output
_testIngressClassMinimal: (#IngressClassTransformer.#transform & {
	#component: {
		metadata: name: "nginx"
		spec: ingressclass: {}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "nginx"}).out
}).output & {
	apiVersion: "networking.k8s.io/v1"
	kind:       "IngressClass"
	metadata: name: "my-release-nginx"
}
