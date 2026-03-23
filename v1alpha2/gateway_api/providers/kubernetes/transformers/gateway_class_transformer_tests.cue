@if(test)
package transformers

// Test: minimal GatewayClass with controllerName
// Asserts: apiVersion, kind, name — NO namespace (cluster-scoped)
_testGatewayClassMinimal: (#GatewayClassTransformer.#transform & {
	#component: {
		metadata: name: "cilium-class"
		spec: gatewayClass: {
			controllerName: "io.cilium/gateway-controller"
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "infra", component: "cilium-class"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "GatewayClass"
	metadata: name: "my-release-cilium-class"
	spec: controllerName: "io.cilium/gateway-controller"
}

// Test: GatewayClass has no namespace (cluster-scoped resource)
// Asserts: metadata does NOT contain namespace field — only name and labels
_testGatewayClassIsClusterScoped: (#GatewayClassTransformer.#transform & {
	#component: {
		metadata: name: "nginx-class"
		spec: gatewayClass: {
			controllerName: "k8s.io/nginx"
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "system", component: "nginx-class"}).out
}).output & {
	kind: "GatewayClass"
	// Verify the name is set correctly without namespace
	metadata: name: "rel-nginx-class"
}
