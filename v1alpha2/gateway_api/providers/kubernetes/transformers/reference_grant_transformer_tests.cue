@if(test)
package transformers

// Test: ReferenceGrant allowing cross-namespace HTTPRoute → Service access
// Asserts: apiVersion, kind, name, namespace, spec.from, spec.to
_testReferenceGrantMinimal: (#ReferenceGrantTransformer.#transform & {
	#component: {
		metadata: name: "allow-routes"
		spec: referenceGrant: {
			from: [{
				group:     "gateway.networking.k8s.io"
				kind:      "HTTPRoute"
				namespace: "gateway-ns"
			}]
			to: [{
				group: ""
				kind:  "Service"
			}]
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "app-ns", component: "allow-routes"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "ReferenceGrant"
	metadata: {
		name:      "my-release-allow-routes"
		namespace: "app-ns"
	}
	spec: from: [{
		group:     "gateway.networking.k8s.io"
		kind:      "HTTPRoute"
		namespace: "gateway-ns"
	}]
	spec: to: [{
		group: ""
		kind:  "Service"
	}]
}

// Test: ReferenceGrant for Secret access (TLS cert cross-namespace)
// Asserts: from/to namespace wiring for Gateway → Secret
_testReferenceGrantForSecrets: (#ReferenceGrantTransformer.#transform & {
	#component: {
		metadata: name: "allow-secrets"
		spec: referenceGrant: {
			from: [{
				group:     "gateway.networking.k8s.io"
				kind:      "Gateway"
				namespace: "infra"
			}]
			to: [{
				group: ""
				kind:  "Secret"
			}]
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "certs", component: "allow-secrets"}).out
}).output & {
	kind:            "ReferenceGrant"
	metadata: name: "rel-allow-secrets"
	spec: from: [{kind: "Gateway", namespace: "infra"}]
	spec: to: [{kind: "Secret"}]
}
