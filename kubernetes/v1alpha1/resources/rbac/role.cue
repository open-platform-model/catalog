package rbac

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Role Resource Definition
/////////////////////////////////////////////////////////////////

// #RoleResource defines a native Kubernetes Role as an OPM resource.
// Use this to grant namespace-scoped permissions to subjects.
#RoleResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/rbac"
		version:     "v1"
		name:        "role"
		description: "A native Kubernetes Role resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	#defaults: #RoleDefaults

	spec: close({role: schemas.#RoleSchema})
}

#RoleComponent: component.#Component & {
	#resources: {(#RoleResource.metadata.fqn): #RoleResource}
}

#RoleDefaults: schemas.#RoleSchema & {}
