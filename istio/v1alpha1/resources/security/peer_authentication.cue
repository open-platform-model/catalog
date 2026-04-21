package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	pa "opmodel.dev/istio/v1alpha1/schemas/istio/security.istio.io/peerauthentication/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// PeerAuthentication Resource Definition
/////////////////////////////////////////////////////////////////

#PeerAuthenticationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/security"
		version:     "v1"
		name:        "peer-authentication"
		description: "An Istio PeerAuthentication resource for mTLS enforcement on workload-to-workload traffic"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	#defaults: #PeerAuthenticationDefaults

	spec: close({peerAuthentication: {
		metadata?: _#metadata
		spec?:     pa.#PeerAuthenticationSpec
	}})
}

#PeerAuthentication: component.#Component & {
	#resources: {(#PeerAuthenticationResource.metadata.fqn): #PeerAuthenticationResource}
}

#PeerAuthenticationDefaults: {
	metadata?: _#metadata
	spec?:     pa.#PeerAuthenticationSpec
}
