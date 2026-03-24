@if(test)
package transformers

// Test: minimal HTTPRoute with gateway ref and path rule
// Asserts: apiVersion, kind, name, namespace, parentRefs, backendRefs
_testHttpRouteMinimal: (#HttpRouteTransformer.#transform & {
	#component: {
		metadata: name: "api"
		spec: httpRoute: {
			gatewayRef: name: "my-gw"
			rules: [{
				backendPort: 8080
			}]
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "prod", component: "api"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      "my-release-api"
		namespace: "prod"
	}
	spec: parentRefs: [{name: "my-gw"}]
	spec: rules: [{
		backendRefs: [{
			name: "my-release-api"
			port: 8080
		}]
	}]
}

// Test: HTTPRoute with path match and method
// Asserts: rules[0].matches[0].path, rules[0].matches[0].method
_testHttpRouteWithPathMatch: (#HttpRouteTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: httpRoute: {
			gatewayRef: name: "ingress-gw"
			rules: [{
				backendPort: 3000
				matches: [{
					path: {type: "PathPrefix", value: "/api"}
					method: "GET"
				}]
			}]
		}
	}
	#context: (#TestCtx & {release: "app", namespace: "default", component: "web"}).out
}).output & {
	kind: "HTTPRoute"
	metadata: name: "app-web"
	spec: rules: [{
		matches: [{
			path: {type: "PathPrefix", value: "/api"}
			method: "GET"
		}]
	}]
}

// Test: HTTPRoute with hostnames
// Asserts: spec.hostnames is propagated
_testHttpRouteWithHostnames: (#HttpRouteTransformer.#transform & {
	#component: {
		metadata: name: "svc"
		spec: httpRoute: {
			gatewayRef: name: "gw"
			hostnames: ["example.com", "www.example.com"]
			rules: [{backendPort: 80}]
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "ns", component: "svc"}).out
}).output & {
	kind: "HTTPRoute"
	spec: hostnames: ["example.com", "www.example.com"]
}
