package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Ingress Resource Definition
/////////////////////////////////////////////////////////////////

// #IngressResource defines a native Kubernetes Ingress as an OPM resource.
// Use this to route external HTTP/HTTPS traffic to in-cluster services.
#IngressResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/network"
		version:     "v1"
		name:        "ingress"
		description: "A native Kubernetes Ingress resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #IngressDefaults

	spec: close({ingress: schemas.#IngressSchema})
}

#Ingress: component.#Component & {
	#resources: {(#IngressResource.metadata.fqn): #IngressResource}
}

#IngressDefaults: schemas.#IngressSchema & {}
