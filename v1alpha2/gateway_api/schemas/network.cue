// Gateway API network schemas
package schemas

//////////////////////////////////////////////////////////////////
//// Route Shared Base Schemas
//////////////////////////////////////////////////////////////////

// Header match for route rules
#RouteHeaderMatch: {
	name!:  string
	value!: string
}

// Base fields shared by all route rules
#RouteRuleBase: {
	backendPort!: uint & >=1 & <=65535
	...
}

// Shared attachment fields for route schemas (gateway, TLS, className)
#RouteAttachmentSchema: {
	gatewayRef?: {
		name!:      string
		namespace?: string
	}
	tls?: {
		mode?: *"Terminate" | "Passthrough"
		certificateRef?: {
			name!:      string
			namespace?: string
		}
	}
	...
}

//////////////////////////////////////////////////////////////////
//// HTTP Route Schemas
//////////////////////////////////////////////////////////////////

// Match criteria for an HTTP route rule
#HttpRouteMatchSchema: {
	path?: {
		type:   *"Prefix" | "Exact" | "RegularExpression"
		value!: string
	}
	headers?: [...#RouteHeaderMatch]
	method?: "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "HEAD" | "OPTIONS"
}

// A single HTTP route rule (embeds RouteRuleBase)
#HttpRouteRuleSchema: #RouteRuleBase & {
	matches?: [...#HttpRouteMatchSchema]
}

// HTTP route specification (embeds RouteAttachmentSchema)
#HttpRouteSchema: #RouteAttachmentSchema & {
	hostnames?: [...string]
	rules: [#HttpRouteRuleSchema, ...#HttpRouteRuleSchema]
}

//////////////////////////////////////////////////////////////////
//// gRPC Route Schemas
//////////////////////////////////////////////////////////////////

// Match criteria for a gRPC route rule
#GrpcRouteMatchSchema: {
	service?: string
	method?:  string
	headers?: [...#RouteHeaderMatch]
}

// A single gRPC route rule (embeds RouteRuleBase)
#GrpcRouteRuleSchema: #RouteRuleBase & {
	matches?: [...#GrpcRouteMatchSchema]
}

// gRPC route specification (embeds RouteAttachmentSchema)
#GrpcRouteSchema: #RouteAttachmentSchema & {
	hostnames?: [...string]
	rules: [#GrpcRouteRuleSchema, ...#GrpcRouteRuleSchema]
}

//////////////////////////////////////////////////////////////////
//// TCP Route Schemas
//////////////////////////////////////////////////////////////////

// A single TCP route rule (embeds RouteRuleBase, no L7 match fields)
#TcpRouteRuleSchema: #RouteRuleBase

// TCP route specification (embeds RouteAttachmentSchema)
#TcpRouteSchema: #RouteAttachmentSchema & {
	rules: [#TcpRouteRuleSchema, ...#TcpRouteRuleSchema]
}

//////////////////////////////////////////////////////////////////
//// TLS Route Schemas
//////////////////////////////////////////////////////////////////

// A single TLS route rule (embeds RouteRuleBase, no L7 match fields)
#TlsRouteRuleSchema: #RouteRuleBase

// TLS route specification (embeds RouteAttachmentSchema)
#TlsRouteSchema: #RouteAttachmentSchema & {
	hostnames?: [...string]
	rules: [#TlsRouteRuleSchema, ...#TlsRouteRuleSchema]
}

//////////////////////////////////////////////////////////////////
//// Gateway Schemas
//////////////////////////////////////////////////////////////////

// A single Gateway listener
#ListenerSchema: {
	name!:     string
	protocol!: "HTTP" | "HTTPS" | "TLS" | "TCP" | "UDP"
	port!:     uint & >=1 & <=65535
	hostname?: string
	tls?: {
		mode:             *"Terminate" | "Passthrough"
		certificateRef?: {
			name!:      string
			namespace?: string
		}
	}
	allowedRoutes?: {
		namespaces?: {
			from: *"Same" | "All" | "Selector"
		}
	}
}

// Gateway resource spec
#GatewaySchema: {
	gatewayClassName!: string
	listeners!: [#ListenerSchema, ...#ListenerSchema]
	// Optional cert-manager integration: annotates Gateway to request TLS certificates
	issuerRef?: {
		name!:  string
		kind:   *"Issuer" | "ClusterIssuer"
		group?: string
	}
	addresses?: [...{
		type?:  string
		value!: string
	}]
	// Optional infrastructure configuration for the Gateway
	infrastructure?: {
		annotations?: {[string]: string}
		labels?:      {[string]: string}
		parametersRef?: {
			group?:     string
			kind:       *"ConfigMap" | string
			name!:      string
			namespace?: string
		}
	}
}

//////////////////////////////////////////////////////////////////
//// ReferenceGrant Schemas
//////////////////////////////////////////////////////////////////

#ReferenceGrantFromSchema: {
	group!:     string
	kind!:      string
	namespace!: string
}

#ReferenceGrantToSchema: {
	group!: string
	kind!:  string
	name?:  string
}

// ReferenceGrant spec — permits cross-namespace access between resources
#ReferenceGrantSchema: {
	from!: [#ReferenceGrantFromSchema, ...#ReferenceGrantFromSchema]
	to!:   [#ReferenceGrantToSchema, ...#ReferenceGrantToSchema]
}

//////////////////////////////////////////////////////////////////
//// GatewayClass Schemas
//////////////////////////////////////////////////////////////////

// GatewayClass spec — defines a class of Gateways
#GatewayClassSchema: {
	controllerName!: string
	description?:    string
	parametersRef?: {
		group!:     string
		kind!:      string
		name!:      string
		namespace?: string
	}
}

//////////////////////////////////////////////////////////////////
//// BackendTrafficPolicy Schemas
//////////////////////////////////////////////////////////////////

#BackendTrafficPolicyTargetRef: {
	group!:     string
	kind!:      string
	name!:      string
	namespace?: string
}

// BackendTrafficPolicy spec — configures traffic behaviour for a backend
#BackendTrafficPolicySchema: {
	targetRef!: #BackendTrafficPolicyTargetRef
	sessionPersistence?: {
		sessionName?: string
		type?:        "Cookie" | "Header"
		cookieConfig?: {
			lifetimeType?: "Session" | "Permanent"
		}
		absoluteTimeout?: string
		idleTimeout?:     string
	}
	retry?: {
		codes?:    [...int]
		attempts?: int & >=1
		backoff?:  string
	}
}
