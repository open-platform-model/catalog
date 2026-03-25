package rbac

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// RoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// #RoleBindingResource defines a native Kubernetes RoleBinding as an OPM resource.
// Use this to bind a Role or ClusterRole to subjects within a namespace.
#RoleBindingResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/rbac"
		version:     "v1"
		name:        "rolebinding"
		description: "A native Kubernetes RoleBinding resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	#defaults: #RoleBindingDefaults

	spec: close({rolebinding: schemas.#RoleBindingSchema})
}

#RoleBindingComponent: component.#Component & {
	#resources: {(#RoleBindingResource.metadata.fqn): #RoleBindingResource}
}

#RoleBindingDefaults: schemas.#RoleBindingSchema & {}
