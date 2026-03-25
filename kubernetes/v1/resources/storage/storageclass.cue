package storage

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// StorageClass Resource Definition
/////////////////////////////////////////////////////////////////

// #StorageClassResource defines a native Kubernetes StorageClass as an OPM resource.
// Use this to define cluster-wide storage provisioner configurations.
#StorageClassResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/storage"
		version:     "v1"
		name:        "storageclass"
		description: "A native Kubernetes StorageClass resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	#defaults: #StorageClassDefaults

	spec: close({storageclass: schemas.#StorageClassSchema})
}

#StorageClass: component.#Component & {
	#resources: {(#StorageClassResource.metadata.fqn): #StorageClassResource}
}

#StorageClassDefaults: schemas.#StorageClassSchema & {}
