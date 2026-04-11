@if(test)

package transformers

// Test: minimal Gateway with gatewayClassName and listeners
_testGatewayMinimal: (#GatewayTransformer.#transform & {
	#component: {
		metadata: name: "main-gw"
		spec: gateway: {
			spec: {
				gatewayClassName: "cilium"
				listeners: [{
					name:     "http"
					port:     80
					protocol: "HTTP"
				}]
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "infra", component: "main-gw"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "Gateway"
	metadata: {
		name:      "my-release-main-gw"
		namespace: "infra"
	}
	spec: gatewayClassName: "cilium"
}

// Test: Gateway with multiple listeners — spec passthrough
_testGatewayMultipleListeners: (#GatewayTransformer.#transform & {
	#component: {
		metadata: name: "dual-gw"
		spec: gateway: {
			spec: {
				gatewayClassName: "nginx"
				listeners: [{
					name:     "http"
					port:     80
					protocol: "HTTP"
				}, {
					name:     "https"
					port:     443
					protocol: "HTTPS"
				}]
			}
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "gw-ns", component: "dual-gw"}).out
}).output & {
	kind: "Gateway"
	metadata: name:         "rel-dual-gw"
	spec: gatewayClassName: "nginx"
}
