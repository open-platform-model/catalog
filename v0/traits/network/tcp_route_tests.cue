@if(test)

package network

// =============================================================================
// TCP Route Trait Tests
// =============================================================================

// Test: TcpRoute component helper
_testTcpRouteComponent: #TcpRoute & {
	metadata: name: "tcp-route-test"
	spec: tcpRoute: {
		rules: [{
			backendPort: 5432
		}]
	}
}
