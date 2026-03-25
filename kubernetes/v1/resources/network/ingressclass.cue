package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// IngressClass Resource Definition
/////////////////////////////////////////////////////////////////

// #IngressClassResource defines a native Kubernetes IngressClass as an OPM resource.
// Use this to configure cluster-scoped ingress controller implementations.
#IngressClassResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/network"
		version:     "v1"
		name:        "ingressclass"
		description: "A native Kubernetes IngressClass resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #IngressClassDefaults

	spec: close({ingressclass: schemas.#IngressClassSchema})
}

#IngressClass: component.#Component & {
	#resources: {(#IngressClassResource.metadata.fqn): #IngressClassResource}
}

#IngressClassDefaults: schemas.#IngressClassSchema & {}
