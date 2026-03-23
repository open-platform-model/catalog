@if(test)
package transformers

// Test: minimal GRPCRoute with gateway ref
// Asserts: apiVersion, kind, name, namespace, parentRefs, backendRefs
_testGrpcRouteMinimal: (#GrpcRouteTransformer.#transform & {
	#component: {
		metadata: name: "grpc-svc"
		spec: grpcRoute: {
			gatewayRef: name: "grpc-gw"
			rules: [{
				backendPort: 9090
			}]
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "prod", component: "grpc-svc"}).out
}).output & {
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "GRPCRoute"
	metadata: {
		name:      "my-release-grpc-svc"
		namespace: "prod"
	}
	spec: parentRefs: [{name: "grpc-gw"}]
	spec: rules: [{
		backendRefs: [{
			name: "my-release-grpc-svc"
			port: 9090
		}]
	}]
}

// Test: GRPCRoute with service and method match
// Asserts: rules[0].matches[0].method.service and method
_testGrpcRouteWithMethodMatch: (#GrpcRouteTransformer.#transform & {
	#component: {
		metadata: name: "rpc"
		spec: grpcRoute: {
			gatewayRef: name: "gw"
			rules: [{
				backendPort: 50051
				matches: [{
					service: "com.example.UserService"
					method:  "GetUser"
				}]
			}]
		}
	}
	#context: (#TestCtx & {release: "app", namespace: "default", component: "rpc"}).out
}).output & {
	kind:            "GRPCRoute"
	metadata: name: "app-rpc"
	spec: rules: [{
		matches: [{
			method: {
				service: "com.example.UserService"
				method:  "GetUser"
			}
		}]
	}]
}
