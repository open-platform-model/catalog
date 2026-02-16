@if(test)

package network

// =============================================================================
// HTTP Route Trait Tests
// =============================================================================

// Test: HttpRoute component helper
_testHttpRouteComponent: #HttpRoute & {
	metadata: name: "http-route-test"
	spec: httpRoute: {
		hostnames: ["example.com"]
		rules: [{
			backendPort: 8080
			matches: [{
				path: {
					type:  "Prefix"
					value: "/"
				}
			}]
		}]
	}
}

// Test: HttpRoute with TLS
_testHttpRouteTLS: #HttpRoute & {
	metadata: name: "http-route-tls"
	spec: httpRoute: {
		hostnames: ["secure.example.com"]
		tls: {
			mode: "Terminate"
			certificateRef: name: "tls-cert"
		}
		rules: [{
			backendPort: 8443
		}]
	}
}
