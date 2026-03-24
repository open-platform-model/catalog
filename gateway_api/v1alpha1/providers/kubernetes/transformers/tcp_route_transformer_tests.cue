@if(test)
package transformers

// Test: minimal TCPRoute with gateway ref and backend port
// Asserts: apiVersion, kind, name, namespace, parentRefs, backendRefs
_testTcpRouteMinimal: (#TcpRouteTransformer.#transform & {
	#component: {
		metadata: name: "db-proxy"
		spec: tcpRoute: {
			gatewayRef: name: "tcp-gw"
			rules: [{
				backendPort: 5432
			}]
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "data", component: "db-proxy"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1alpha2"
	kind:       "TCPRoute"
	metadata: {
		name:      "my-release-db-proxy"
		namespace: "data"
	}
	spec: parentRefs: [{name: "tcp-gw"}]
	spec: rules: [{
		backendRefs: [{
			name: "my-release-db-proxy"
			port: 5432
		}]
	}]
}

// Test: TCPRoute with gateway namespace
// Asserts: parentRefs[0].namespace is set when gatewayRef.namespace is provided
_testTcpRouteWithGatewayNamespace: (#TcpRouteTransformer.#transform & {
	#component: {
		metadata: name: "cache"
		spec: tcpRoute: {
			gatewayRef: {
				name:      "infra-gw"
				namespace: "infra"
			}
			rules: [{backendPort: 6379}]
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "app", component: "cache"}).out
}).output & {
	kind: "TCPRoute"
	spec: parentRefs: [{
		name:      "infra-gw"
		namespace: "infra"
	}]
}
