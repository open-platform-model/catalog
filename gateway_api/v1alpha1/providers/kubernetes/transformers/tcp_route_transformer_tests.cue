@if(test)

package transformers

// Test: minimal TCPRoute with parentRefs
_testTcpRouteMinimal: (#TcpRouteTransformer.#transform & {
	#component: {
		metadata: name: "db-proxy"
		spec: tcpRoute: {
			spec: {
				parentRefs: [{name: "tcp-gw"}]
				rules: [{
					backendRefs: [{name: "db-svc", port: 5432}]
				}]
			}
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
}

// Test: TCPRoute with cross-namespace gateway ref — spec passthrough
_testTcpRouteWithGatewayNamespace: (#TcpRouteTransformer.#transform & {
	#component: {
		metadata: name: "cache"
		spec: tcpRoute: {
			spec: {
				parentRefs: [{name: "infra-gw", namespace: "infra"}]
				rules: [{backendRefs: [{name: "cache-svc", port: 6379}]}]
			}
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "app", component: "cache"}).out
}).output & {
	kind: "TCPRoute"
	spec: parentRefs: [{name: "infra-gw", namespace: "infra"}]
}
