@if(test)

package transformers

// Test: minimal GatewayClass — cluster-scoped, no namespace in output
_testGatewayClassMinimal: (#GatewayClassTransformer.#transform & {
	#component: {
		metadata: name: "cilium-class"
		spec: gatewayClass: {
			spec: {
				controllerName: "io.cilium/gateway-controller"
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "infra", component: "cilium-class"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "GatewayClass"
	metadata: name:       "my-release-cilium-class"
	spec: controllerName: "io.cilium/gateway-controller"
}

// Test: GatewayClass has no namespace (cluster-scoped resource)
_testGatewayClassIsClusterScoped: (#GatewayClassTransformer.#transform & {
	#component: {
		metadata: name: "nginx-class"
		spec: gatewayClass: {
			spec: controllerName: "k8s.io/nginx"
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "system", component: "nginx-class"}).out
}).output & {
	kind: "GatewayClass"
	metadata: name: "rel-nginx-class"
}
