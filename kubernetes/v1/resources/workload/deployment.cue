package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Deployment Resource Definition
/////////////////////////////////////////////////////////////////

// #DeploymentResource defines a native Kubernetes Deployment as an OPM resource.
// Use this when you need direct control over the Deployment spec without
// OPM's portable Container abstraction.
#DeploymentResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/workload"
		version:     "v1"
		name:        "deployment"
		description: "A native Kubernetes Deployment resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #DeploymentDefaults

	spec: close({deployment: schemas.#DeploymentSchema})
}

#Deployment: component.#Component & {
	#resources: {(#DeploymentResource.metadata.fqn): #DeploymentResource}
}

#DeploymentDefaults: schemas.#DeploymentSchema & {}
