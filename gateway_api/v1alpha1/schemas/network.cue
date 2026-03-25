// Gateway API network schemas for OPM native resource definitions.
package schemas

// #GatewaySchema accepts the full Gateway API Gateway spec.
#GatewaySchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		gatewayClassName?: string
		listeners?: [...]
		addresses?: [...]
		...
	}
	...
}

// #GatewayClassSchema accepts the full Gateway API GatewayClass spec.
#GatewayClassSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		controllerName?: string
		description?:    string
		parametersRef?: {...}
		...
	}
	...
}

// #HttpRouteSchema accepts the full Gateway API HTTPRoute spec.
#HttpRouteSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		parentRefs?: [...]
		hostnames?: [...]
		rules?: [...]
		...
	}
	...
}

// #GrpcRouteSchema accepts the full Gateway API GRPCRoute spec.
#GrpcRouteSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		parentRefs?: [...]
		hostnames?: [...]
		rules?: [...]
		...
	}
	...
}

// #TcpRouteSchema accepts the full Gateway API TCPRoute spec.
#TcpRouteSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		parentRefs?: [...]
		rules?: [...]
		...
	}
	...
}

// #TlsRouteSchema accepts the full Gateway API TLSRoute spec.
#TlsRouteSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		parentRefs?: [...]
		hostnames?: [...]
		rules?: [...]
		...
	}
	...
}

// #ReferenceGrantSchema accepts the full Gateway API ReferenceGrant spec.
#ReferenceGrantSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		from?: [...]
		to?: [...]
		...
	}
	...
}

// #BackendTrafficPolicySchema accepts the full Gateway API BackendTrafficPolicy spec.
#BackendTrafficPolicySchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		targetRefs?: [...]
		sessionPersistence?: {...}
		retry?: {...}
		...
	}
	...
}
