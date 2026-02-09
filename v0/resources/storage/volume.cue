package storage

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

//////////////////////////////////////////////////////////////////
//// Volume Resource Definition
/////////////////////////////////////////////////////////////////

#VolumesResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/storage@v0"
		name:        "volumes"
		description: "A volume definition for workloads"
		labels: {
			"core.opmodel.dev/persistence": "true"
		}
	}

	// Default values for volumes resource
	#defaults: #VolumesDefaults

	// OpenAPIv3-compatible schema defining the structure of the volume spec
	#spec: volumes: [volumeName=string]: schemas.#VolumeSchema & {name: string | *volumeName}
})

#Volumes: close(core.#Component & {
	metadata: annotations: {
		"transformer.opmodel.dev/list-output": true
	}

	#resources: {(#VolumesResource.metadata.fqn): #VolumesResource}
})

#VolumesDefaults: close(schemas.#VolumeSchema & {
	// Default empty dir medium
	emptyDir?: {
		medium: *"node" | "memory"
	}
})
