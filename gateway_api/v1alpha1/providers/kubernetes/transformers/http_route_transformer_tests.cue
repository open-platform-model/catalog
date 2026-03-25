@if(test)

package transformers

// Test: minimal HTTPRoute with parentRefs and rules
_testHttpRouteMinimal: (#HttpRouteTransformer.#transform & {
	#component: {
		metadata: name: "api"
		spec: httpRoute: {
			spec: {
				parentRefs: [{name: "my-gw"}]
				rules: [{
					backendRefs: [{name: "api-svc", port: 8080}]
				}]
			}
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
}

// Test: HTTPRoute with hostnames and path match — spec passthrough
_testHttpRouteWithHostnames: (#HttpRouteTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: httpRoute: {
			spec: {
				parentRefs: [{name: "ingress-gw"}]
				hostnames: ["example.com", "www.example.com"]
				rules: [{
					matches: [{path: {type: "PathPrefix", value: "/api"}}]
					backendRefs: [{name: "web-svc", port: 3000}]
				}]
			}
		}
	}
	#context: (#TestCtx & {release: "app", namespace: "default", component: "web"}).out
}).output & {
	kind: "HTTPRoute"
	metadata: name: "app-web"
	spec: hostnames: ["example.com", "www.example.com"]
}
