package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// NetworkPolicy Resource Definition
/////////////////////////////////////////////////////////////////

// #NetworkPolicyResource defines a native Kubernetes NetworkPolicy as an OPM resource.
// Use this to control ingress and egress traffic between pods.
#NetworkPolicyResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/network"
		version:     "v1"
		name:        "networkpolicy"
		description: "A native Kubernetes NetworkPolicy resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #NetworkPolicyDefaults

	spec: close({networkpolicy: schemas.#NetworkPolicySchema})
}

#NetworkPolicy: component.#Component & {
	#resources: {(#NetworkPolicyResource.metadata.fqn): #NetworkPolicyResource}
}

#NetworkPolicyDefaults: schemas.#NetworkPolicySchema & {}
