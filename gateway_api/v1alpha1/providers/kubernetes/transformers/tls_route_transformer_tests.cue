@if(test)

package transformers

// Test: minimal TLSRoute with parentRefs
_testTlsRouteMinimal: (#TlsRouteTransformer.#transform & {
	#component: {
		metadata: name: "secure-svc"
		spec: tlsRoute: {
			spec: {
				parentRefs: [{name: "tls-gw"}]
				rules: [{
					backendRefs: [{name: "secure-backend", port: 8443}]
				}]
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "prod", component: "secure-svc"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1alpha2"
	kind:       "TLSRoute"
	metadata: {
		name:      "my-release-secure-svc"
		namespace: "prod"
	}
	spec: parentRefs: [{name: "tls-gw"}]
}

// Test: TLSRoute with hostnames — spec passthrough
_testTlsRouteWithHostnames: (#TlsRouteTransformer.#transform & {
	#component: {
		metadata: name: "tls-svc"
		spec: tlsRoute: {
			spec: {
				parentRefs: [{name: "gw"}]
				hostnames: ["secure.example.com"]
				rules: [{backendRefs: [{name: "backend", port: 443}]}]
			}
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "ns", component: "tls-svc"}).out
}).output & {
	kind: "TLSRoute"
	spec: hostnames: ["secure.example.com"]
}
