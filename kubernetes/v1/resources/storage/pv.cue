package storage

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolume Resource Definition
/////////////////////////////////////////////////////////////////

// #PersistentVolumeResource defines a native Kubernetes PV as an OPM resource.
// Use this for cluster-scoped persistent volume provisioning.
#PersistentVolumeResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/storage"
		version:     "v1"
		name:        "persistentvolume"
		description: "A native Kubernetes PersistentVolume resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	#defaults: #PersistentVolumeDefaults

	spec: close({persistentvolume: schemas.#PersistentVolumeSchema})
}

#PersistentVolume: component.#Component & {
	#resources: {(#PersistentVolumeResource.metadata.fqn): #PersistentVolumeResource}
}

#PersistentVolumeDefaults: schemas.#PersistentVolumeSchema & {}
