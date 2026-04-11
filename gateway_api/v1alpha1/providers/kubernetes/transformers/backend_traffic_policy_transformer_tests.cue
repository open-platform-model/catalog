@if(test)

package transformers

// Test: minimal BackendTrafficPolicy with targetRefs
_testBackendTrafficPolicyMinimal: (#BackendTrafficPolicyTransformer.#transform & {
	#component: {
		metadata: name: "api-policy"
		spec: backendTrafficPolicy: {
			spec: {
				targetRefs: [{
					group: ""
					kind:  "Service"
					name:  "my-release-api"
				}]
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "prod", component: "api-policy"}).out
}).output & {
	apiVersion: "gateway.networking.x-k8s.io/v1alpha1"
	kind:       "XBackendTrafficPolicy"
	metadata: {
		name:      "my-release-api-policy"
		namespace: "prod"
	}
	spec: targetRefs: [{
		group: ""
		kind:  "Service"
		name:  "my-release-api"
	}]
}

// Test: BackendTrafficPolicy with sessionPersistence — spec passthrough
_testBackendTrafficPolicyWithSessionPersistence: (#BackendTrafficPolicyTransformer.#transform & {
	#component: {
		metadata: name: "sticky-policy"
		spec: backendTrafficPolicy: {
			spec: {
				targetRefs: [{
					group: ""
					kind:  "Service"
					name:  "rel-svc"
				}]
				sessionPersistence: {
					type: "Cookie"
				}
			}
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "ns", component: "sticky-policy"}).out
}).output & {
	kind: "XBackendTrafficPolicy"
	spec: sessionPersistence: type: "Cookie"
}
