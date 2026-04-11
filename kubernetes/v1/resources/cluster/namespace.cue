package cluster

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Namespace Resource Definition
/////////////////////////////////////////////////////////////////

// #NamespaceResource defines a native Kubernetes Namespace as an OPM resource.
// Use this to create and manage cluster-scoped namespace isolation boundaries.
#NamespaceResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/cluster"
		version:     "v1"
		name:        "namespace"
		description: "A native Kubernetes Namespace resource"
		labels: {
			"resource.opmodel.dev/category": "cluster"
		}
	}

	#defaults: #NamespaceDefaults

	spec: close({namespace: schemas.#NamespaceSchema})
}

#Namespace: component.#Component & {
	#resources: {(#NamespaceResource.metadata.fqn): #NamespaceResource}
}

#NamespaceDefaults: schemas.#NamespaceSchema & {}
