@if(test)

package network

// =============================================================================
// gRPC Route Trait Tests
// =============================================================================

// Test: GrpcRoute component helper
_testGrpcRouteComponent: #GrpcRoute & {
	metadata: name: "grpc-route-test"
	spec: grpcRoute: {
		hostnames: ["grpc.example.com"]
		rules: [{
			backendPort: 9090
			matches: [{
				service: "my.package.Service"
				method:  "GetItem"
			}]
		}]
	}
}
