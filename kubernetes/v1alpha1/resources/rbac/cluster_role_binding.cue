package rbac

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ClusterRoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// #ClusterRoleBindingResource defines a native Kubernetes ClusterRoleBinding as an OPM resource.
// Use this to bind a ClusterRole to subjects cluster-wide.
#ClusterRoleBindingResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/rbac"
		version:     "v1"
		name:        "clusterrolebinding"
		description: "A native Kubernetes ClusterRoleBinding resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	#defaults: #ClusterRoleBindingDefaults

	spec: close({clusterrolebinding: schemas.#ClusterRoleBindingSchema})
}

#ClusterRoleBindingComponent: component.#Component & {
	#resources: {(#ClusterRoleBindingResource.metadata.fqn): #ClusterRoleBindingResource}
}

#ClusterRoleBindingDefaults: schemas.#ClusterRoleBindingSchema & {}
