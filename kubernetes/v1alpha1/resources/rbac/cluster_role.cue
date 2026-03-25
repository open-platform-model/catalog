package rbac

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ClusterRole Resource Definition
/////////////////////////////////////////////////////////////////

// #ClusterRoleResource defines a native Kubernetes ClusterRole as an OPM resource.
// Use this to grant cluster-scoped permissions or namespace permissions across all namespaces.
#ClusterRoleResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/rbac"
		version:     "v1"
		name:        "clusterrole"
		description: "A native Kubernetes ClusterRole resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	#defaults: #ClusterRoleDefaults

	spec: close({clusterrole: schemas.#ClusterRoleSchema})
}

#ClusterRoleComponent: component.#Component & {
	#resources: {(#ClusterRoleResource.metadata.fqn): #ClusterRoleResource}
}

#ClusterRoleDefaults: schemas.#ClusterRoleSchema & {}
