package rbac

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ServiceAccount Resource Definition
/////////////////////////////////////////////////////////////////

// #ServiceAccountResource defines a native Kubernetes ServiceAccount as an OPM resource.
// Use this to provide an identity for processes running in pods.
#ServiceAccountResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/rbac"
		version:     "v1"
		name:        "serviceaccount"
		description: "A native Kubernetes ServiceAccount resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	#defaults: #ServiceAccountDefaults

	spec: close({serviceaccount: schemas.#ServiceAccountSchema})
}

#ServiceAccount: component.#Component & {
	#resources: {(#ServiceAccountResource.metadata.fqn): #ServiceAccountResource}
}

#ServiceAccountDefaults: schemas.#ServiceAccountSchema & {}
