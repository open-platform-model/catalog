package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	ap "opmodel.dev/istio/v1alpha1/schemas/istio/security.istio.io/authorizationpolicy/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// AuthorizationPolicy Resource Definition
/////////////////////////////////////////////////////////////////

#AuthorizationPolicyResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/security"
		version:     "v1"
		name:        "authorization-policy"
		description: "An Istio AuthorizationPolicy resource for workload-level access control"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	#defaults: #AuthorizationPolicyDefaults

	spec: close({authorizationPolicy: {
		metadata?: _#metadata
		spec?:     ap.#AuthorizationPolicySpec
	}})
}

#AuthorizationPolicy: component.#Component & {
	#resources: {(#AuthorizationPolicyResource.metadata.fqn): #AuthorizationPolicyResource}
}

#AuthorizationPolicyDefaults: {
	metadata?: _#metadata
	spec?:     ap.#AuthorizationPolicySpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
