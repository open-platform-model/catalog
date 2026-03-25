package storage

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolumeClaim Resource Definition
/////////////////////////////////////////////////////////////////

// #PersistentVolumeClaimResource defines a native Kubernetes PVC as an OPM resource.
// Use this to request persistent storage for stateful workloads.
#PersistentVolumeClaimResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/storage"
		version:     "v1"
		name:        "persistentvolumeclaim"
		description: "A native Kubernetes PersistentVolumeClaim resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	#defaults: #PersistentVolumeClaimDefaults

	spec: close({persistentvolumeclaim: schemas.#PersistentVolumeClaimSchema})
}

#PersistentVolumeClaimComponent: component.#Component & {
	#resources: {(#PersistentVolumeClaimResource.metadata.fqn): #PersistentVolumeClaimResource}
}

#PersistentVolumeClaimDefaults: schemas.#PersistentVolumeClaimSchema & {}
