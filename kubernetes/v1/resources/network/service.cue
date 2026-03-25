package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Service Resource Definition
/////////////////////////////////////////////////////////////////

// #ServiceResource defines a native Kubernetes Service as an OPM resource.
// Use this to expose workloads within or outside the cluster.
#ServiceResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/network"
		version:     "v1"
		name:        "service"
		description: "A native Kubernetes Service resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #ServiceDefaults

	spec: close({service: schemas.#ServiceSchema})
}

#Service: component.#Component & {
	#resources: {(#ServiceResource.metadata.fqn): #ServiceResource}
}

#ServiceDefaults: schemas.#ServiceSchema & {}
