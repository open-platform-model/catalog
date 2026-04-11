@if(test)

package transformers

// Test: minimal NetworkPolicy with required fields
_testNetworkPolicyMinimal: (#NetworkPolicyTransformer.#transform & {
	#component: {
		metadata: name: "allow-web"
		spec: networkpolicy: {
			spec: podSelector: {}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "allow-web"}).out
}).output & {
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "my-release-allow-web"
		namespace: "default"
	}
}
