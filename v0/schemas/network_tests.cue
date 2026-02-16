@if(test)

package schemas

// =============================================================================
// Network Schema Tests
// =============================================================================

// ── PortSchema ───────────────────────────────────────────────────

_testPortMinimal: #PortSchema & {
	name:       "http"
	targetPort: 80
}

_testPortFull: #PortSchema & {
	name:        "https"
	targetPort:  8443
	protocol:    "TCP"
	hostIP:      "0.0.0.0"
	hostPort:    443
	exposedPort: 443
}

_testPortUDP: #PortSchema & {
	name:       "dns"
	targetPort: 53
	protocol:   "UDP"
}

_testPortSCTP: #PortSchema & {
	name:       "sctp-svc"
	targetPort: 3868
	protocol:   "SCTP"
}

// ── ExposeSchema ─────────────────────────────────────────────────

_testExposeClusterIP: #ExposeSchema & {
	ports: {
		http: {
			name:       "http"
			targetPort: 80
		}
	}
	type: "ClusterIP"
}

_testExposeLoadBalancer: #ExposeSchema & {
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

// ── HttpRouteSchema ──────────────────────────────────────────────

_testHttpRouteBasic: #HttpRouteSchema & {
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

_testHttpRouteFull: #HttpRouteSchema & {
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

// ── GrpcRouteSchema ──────────────────────────────────────────────

_testGrpcRoute: #GrpcRouteSchema & {
	hostnames: ["grpc.example.com"]
	rules: [{
		backendPort: 9090
		matches: [{
			service: "my.package.Service"
			method:  "GetItem"
		}]
	}]
}

// ── TcpRouteSchema ───────────────────────────────────────────────

_testTcpRoute: #TcpRouteSchema & {
	rules: [{
		backendPort: 5432
	}]
}

// ── IANA_SVC_NAME ────────────────────────────────────────────────

_testIANASimple:   #IANA_SVC_NAME & "http"
_testIANAHyphen:   #IANA_SVC_NAME & "my-svc"
_testIANAMax15:    #IANA_SVC_NAME & "abcdefghijklmno"
_testIANASingleCh: #IANA_SVC_NAME & "x"

// ── RouteAttachmentSchema (previously untested) ──────────────────

_testRouteAttachmentTerminate: #RouteAttachmentSchema & {
	gatewayRef: {
		name:      "gateway"
		namespace: "default"
	}
	tls: {
		mode: "Terminate"
		certificateRef: {
			name: "cert"
		}
	}
}

_testRouteAttachmentPassthrough: #RouteAttachmentSchema & {
	gatewayRef: {
		name: "gateway"
	}
	tls: {
		mode: "Passthrough"
	}
}

// =============================================================================
// Negative Tests
// =============================================================================

// ── PortSchema Negatives ─────────────────────────────────────────

// Negative tests moved to testdata/*.yaml files

_testPortBoundaryMin: #PortSchema & {
	name:       "min"
	targetPort: 1
}

_testPortBoundaryMax: #PortSchema & {
	name:       "max"
	targetPort: 65535
}

// Negative tests moved to testdata/*.yaml files (IANA_SVC_NAME tests removed as scalar types)

// Test NodePort type (valid, was missing)
_testExposeNodePort: #ExposeSchema & {
	ports: {
		http: {
			name:       "http"
			targetPort: 8080
		}
	}
	type: "NodePort"
}

// Negative tests moved to testdata/*.yaml files

// Test all HTTP methods (was missing)
_testHttpRouteAllMethods: #HttpRouteSchema & {
	hostnames: ["api.example.com"]
	rules: [
		{
			backendPort: 8080
			matches: [{
				path: {type: "Prefix", value: "/get"}
				method: "GET"
			}]
		},
		{
			backendPort: 8080
			matches: [{
				path: {type: "Prefix", value: "/post"}
				method: "POST"
			}]
		},
		{
			backendPort: 8080
			matches: [{
				path: {type: "Prefix", value: "/put"}
				method: "PUT"
			}]
		},
		{
			backendPort: 8080
			matches: [{
				path: {type: "Prefix", value: "/delete"}
				method: "DELETE"
			}]
		},
		{
			backendPort: 8080
			matches: [{
				path: {type: "Prefix", value: "/patch"}
				method: "PATCH"
			}]
		},
	]
}
