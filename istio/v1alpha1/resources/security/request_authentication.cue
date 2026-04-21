package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	ra "opmodel.dev/istio/v1alpha1/schemas/istio/security.istio.io/requestauthentication/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// RequestAuthentication Resource Definition
/////////////////////////////////////////////////////////////////

#RequestAuthenticationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/security"
		version:     "v1"
		name:        "request-authentication"
		description: "An Istio RequestAuthentication resource — JWT validation rules applied to incoming requests"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	#defaults: #RequestAuthenticationDefaults

	spec: close({requestAuthentication: {
		metadata?: _#metadata
		spec?:     ra.#RequestAuthenticationSpec
	}})
}

#RequestAuthentication: component.#Component & {
	#resources: {(#RequestAuthenticationResource.metadata.fqn): #RequestAuthenticationResource}
}

#RequestAuthenticationDefaults: {
	metadata?: _#metadata
	spec?:     ra.#RequestAuthenticationSpec
}
