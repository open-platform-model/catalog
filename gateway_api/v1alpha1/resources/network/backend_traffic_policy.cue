package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	btp "opmodel.dev/gateway_api/v1alpha1/schemas/gateway/gateway.networking.x-k8s.io/xbackendtrafficpolicy/v1alpha1@v1"
)

/////////////////////////////////////////////////////////////////
//// BackendTrafficPolicy Resource Definition
/////////////////////////////////////////////////////////////////

#BackendTrafficPolicyResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/resources/network"
		version:     "v1"
		name:        "backend-traffic-policy"
		description: "A BackendTrafficPolicy resource for configuring backend traffic"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #BackendTrafficPolicyDefaults

	spec: close({backendTrafficPolicy: {
		metadata?: _#metadata
		spec?:     btp.#XBackendTrafficPolicySpec
	}})
}

#BackendTrafficPolicy: component.#Component & {
	#resources: {(#BackendTrafficPolicyResource.metadata.fqn): #BackendTrafficPolicyResource}
}

#BackendTrafficPolicyDefaults: {
	metadata?: _#metadata
	spec?:     btp.#XBackendTrafficPolicySpec
}
