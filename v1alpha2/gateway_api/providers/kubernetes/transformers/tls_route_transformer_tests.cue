@if(test)
package transformers

// Test: minimal TLSRoute with gateway ref and backend port
// Asserts: apiVersion, kind, name, namespace, parentRefs, backendRefs
_testTlsRouteMinimal: (#TlsRouteTransformer.#transform & {
	#component: {
		metadata: name: "secure-svc"
		spec: tlsRoute: {
			gatewayRef: name: "tls-gw"
			rules: [{
				backendPort: 8443
			}]
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
	spec: rules: [{
		backendRefs: [{
			name: "my-release-secure-svc"
			port: 8443
		}]
	}]
}

// Test: TLSRoute with hostnames
// Asserts: spec.hostnames is propagated to TLSRoute output
_testTlsRouteWithHostnames: (#TlsRouteTransformer.#transform & {
	#component: {
		metadata: name: "tls-svc"
		spec: tlsRoute: {
			gatewayRef: name: "gw"
			hostnames: ["secure.example.com"]
			rules: [{backendPort: 443}]
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "ns", component: "tls-svc"}).out
}).output & {
	kind: "TLSRoute"
	spec: hostnames: ["secure.example.com"]
}
