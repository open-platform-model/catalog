package storage

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

//////////////////////////////////////////////////////////////////
//// Volume Resource Definition
/////////////////////////////////////////////////////////////////

#VolumesResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/resources/storage"
		version:     "v1"
		name:        "volumes"
		description: "A volume definition for workloads"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	// Default values for volumes resource
	#defaults: #VolumesDefaults

	// OpenAPIv3-compatible schema defining the structure of the volume spec
	spec: close({volumes: [volumeName=string]: schemas.#VolumeSchema & {name: string | *volumeName}})
}

#Volumes: component.#Component & {

	#resources: {(#VolumesResource.metadata.fqn): #VolumesResource}
}

#VolumesDefaults: schemas.#VolumeSchema & {
	// Default empty dir medium
	emptyDir?: {
		medium: *"node" | "memory"
	}
}
