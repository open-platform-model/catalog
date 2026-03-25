@if(test)

package transformers

// Test: minimal GRPCRoute with parentRefs
_testGrpcRouteMinimal: (#GrpcRouteTransformer.#transform & {
	#component: {
		metadata: name: "grpc-svc"
		spec: grpcRoute: {
			spec: {
				parentRefs: [{name: "grpc-gw"}]
				rules: [{
					backendRefs: [{name: "grpc-backend", port: 9090}]
				}]
			}
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
}

// Test: GRPCRoute with method match — spec passthrough
_testGrpcRouteWithMethodMatch: (#GrpcRouteTransformer.#transform & {
	#component: {
		metadata: name: "rpc"
		spec: grpcRoute: {
			spec: {
				parentRefs: [{name: "gw"}]
				rules: [{
					matches: [{method: {service: "com.example.UserService", method: "GetUser"}}]
					backendRefs: [{name: "rpc-svc", port: 50051}]
				}]
			}
		}
	}
	#context: (#TestCtx & {release: "app", namespace: "default", component: "rpc"}).out
}).output & {
	kind: "GRPCRoute"
	metadata: name: "app-rpc"
}
