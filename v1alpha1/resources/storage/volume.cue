package storage

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
)

//////////////////////////////////////////////////////////////////
//// Volume Resource Definition
/////////////////////////////////////////////////////////////////

#VolumesResource: core.#Resource & {
	metadata: {
		modulePath: "opmodel.dev/resources/storage@v1"
		name:          "volumes"
		description:   "A volume definition for workloads"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	// Default values for volumes resource
	#defaults: #VolumesDefaults

	// OpenAPIv3-compatible schema defining the structure of the volume spec
	spec: close({volumes: [volumeName=string]: schemas.#VolumeSchema & {name: string | *volumeName}})
}

#Volumes: core.#Component & {
	metadata: annotations: {
		"transformer.opmodel.dev/list-output": true
	}

	#resources: {(#VolumesResource.metadata.fqn): #VolumesResource}
}

#VolumesDefaults: schemas.#VolumeSchema & {
	// Default empty dir medium
	emptyDir?: {
		medium: *"node" | "memory"
	}
}
