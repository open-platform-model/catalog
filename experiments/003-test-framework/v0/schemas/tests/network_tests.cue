@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #PortSchema
	// =========================================================================

	"#PortSchema": [

		// ── Positive ──
		{
			name:       "minimal"
			definition: #PortSchema
			input: {
				name:       "http"
				targetPort: 80
			}
			assert: valid: true
		},
		{
			name:       "full"
			definition: #PortSchema
			input: {
				name:        "https"
				targetPort:  8443
				protocol:    "TCP"
				hostIP:      "0.0.0.0"
				hostPort:    443
				exposedPort: 443
			}
			assert: valid: true
		},
		{
			name:       "UDP protocol"
			definition: #PortSchema
			input: {
				name:       "dns"
				targetPort: 53
				protocol:   "UDP"
			}
			assert: valid: true
		},
		{
			name:       "SCTP protocol"
			definition: #PortSchema
			input: {
				name:       "sctp-svc"
				targetPort: 3868
				protocol:   "SCTP"
			}
			assert: valid: true
		},
		{
			name:       "boundary min port"
			definition: #PortSchema
			input: {
				name:       "min"
				targetPort: 1
			}
			assert: valid: true
		},
		{
			name:       "boundary max port"
			definition: #PortSchema
			input: {
				name:       "max"
				targetPort: 65535
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "port zero"
			definition: #PortSchema
			input: {
				name:       "http"
				targetPort: 0
				protocol:   "TCP"
			}
			assert: valid: false
		},
		{
			name:       "port too high"
			definition: #PortSchema
			input: {
				name:       "http"
				targetPort: 70000
				protocol:   "TCP"
			}
			assert: valid: false
		},
		{
			name:       "bad protocol"
			definition: #PortSchema
			input: {
				name:       "http"
				targetPort: 8080
				protocol:   "HTTP"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ExposeSchema
	// =========================================================================

	"#ExposeSchema": [

		// ── Positive ──
		{
			name:       "ClusterIP"
			definition: #ExposeSchema
			input: {
				ports: http: {
					name:       "http"
					targetPort: 80
				}
				type: "ClusterIP"
			}
			assert: valid: true
		},
		{
			name:       "LoadBalancer"
			definition: #ExposeSchema
			input: {
				ports: {
					http: {
						name:       "http"
						targetPort: 80
					}
					https: {
						name:       "https"
						targetPort: 443
					}
				}
				type: "LoadBalancer"
			}
			assert: valid: true
		},
		{
			name:       "NodePort"
			definition: #ExposeSchema
			input: {
				ports: http: {
					name:       "http"
					targetPort: 8080
				}
				type: "NodePort"
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "bad type"
			definition: #ExposeSchema
			input: {
				ports: http: {
					name:       "http"
					targetPort: 80
				}
				type: "ExternalName"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #HttpRouteSchema
	// =========================================================================

	"#HttpRouteSchema": [

		// ── Positive ──
		{
			name:       "basic"
			definition: #HttpRouteSchema
			input: {
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
			assert: valid: true
		},
		{
			name:       "full with TLS and gateway"
			definition: #HttpRouteSchema
			input: {
				hostnames: ["api.example.com"]
				gatewayRef: {
					name:      "main-gateway"
					namespace: "gateway-system"
				}
				tls: {
					mode: "Terminate"
					certificateRef: {
						name:      "api-cert"
						namespace: "cert-manager"
					}
				}
				rules: [
					{
						backendPort: 8080
						matches: [{
							path: {
								type:  "Prefix"
								value: "/api/v1"
							}
							method: "GET"
							headers: [{
								name:  "X-API-Version"
								value: "v1"
							}]
						}]
					},
					{
						backendPort: 8081
						matches: [{
							path: {
								type:  "Exact"
								value: "/health"
							}
						}]
					},
				]
			}
			assert: valid: true
		},
		{
			name:       "all HTTP methods"
			definition: #HttpRouteSchema
			input: {
				hostnames: ["api.example.com"]
				rules: [
					{backendPort: 8080, matches: [{path: {type: "Prefix", value: "/get"}, method: "GET"}]},
					{backendPort: 8080, matches: [{path: {type: "Prefix", value: "/post"}, method: "POST"}]},
					{backendPort: 8080, matches: [{path: {type: "Prefix", value: "/put"}, method: "PUT"}]},
					{backendPort: 8080, matches: [{path: {type: "Prefix", value: "/delete"}, method: "DELETE"}]},
					{backendPort: 8080, matches: [{path: {type: "Prefix", value: "/patch"}, method: "PATCH"}]},
				]
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "empty rules"
			definition: #HttpRouteSchema
			input: {
				hostnames: ["example.com"]
				rules: []
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #GrpcRouteSchema
	// =========================================================================

	"#GrpcRouteSchema": [
		{
			name:       "basic"
			definition: #GrpcRouteSchema
			input: {
				hostnames: ["grpc.example.com"]
				rules: [{
					backendPort: 9090
					matches: [{
						service: "my.package.Service"
						method:  "GetItem"
					}]
				}]
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #TcpRouteSchema
	// =========================================================================

	"#TcpRouteSchema": [
		{
			name:       "basic"
			definition: #TcpRouteSchema
			input: rules: [{backendPort: 5432}]
			assert: valid: true
		},
	]

	// =========================================================================
	// #IANA_SVC_NAME
	// =========================================================================

	"#IANA_SVC_NAME": [
		{name: "simple", definition: #IANA_SVC_NAME, input: "http", assert: valid: true},
		{name: "with hyphen", definition: #IANA_SVC_NAME, input: "my-svc", assert: valid: true},
		{name: "max 15 chars", definition: #IANA_SVC_NAME, input: "abcdefghijklmno", assert: valid: true},
		{name: "single char", definition: #IANA_SVC_NAME, input: "x", assert: valid: true},
	]

	// =========================================================================
	// #RouteAttachmentSchema
	// =========================================================================

	"#RouteAttachmentSchema": [
		{
			name:       "terminate"
			definition: #RouteAttachmentSchema
			input: {
				gatewayRef: {
					name:      "gateway"
					namespace: "default"
				}
				tls: {
					mode: "Terminate"
					certificateRef: name: "cert"
				}
			}
			assert: valid: true
		},
		{
			name:       "passthrough"
			definition: #RouteAttachmentSchema
			input: {
				gatewayRef: name: "gateway"
				tls: mode:        "Passthrough"
			}
			assert: valid: true
		},
	]
}
