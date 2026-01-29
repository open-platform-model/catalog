package transformers

import (
	core "opmodel.dev/core@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
)

// PVCTransformer creates standalone PersistentVolumeClaims from Volume resources
#PVCTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v1"
		name:        "PVCTransformer"
		description: "Creates standalone Kubernetes PersistentVolumeClaims from Volume resources"

		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolumeclaim"
			"core.opmodel.dev/priority":          "5"
		}
	}

	// Required resources - Volumes MUST be present
	requiredResources: {
		"opmodel.dev/resources/storage@v0#Volumes": storage_resources.#VolumesResource
	}

	// No optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// No optional traits
	optionalTraits: {}

	#transform: {
		#component: core.#Component
		#context:   core.#TransformerContext

		// Extract required Volumes resource (will be bottom if not present)
		_volumes: #component.spec.volumes

		// Generate PVC for each volume in the volumes map
		output: {
			for volumeName, volume in _volumes {
				"\(volumeName)": {
					apiVersion: "v1"
					kind:       "PersistentVolumeClaim"
					metadata: {
						name:      volume.name | *volumeName
						namespace: #context.namespace | *"default"
						labels: {
							"app.kubernetes.io/name":      #component.metadata.name
							"app.kubernetes.io/component": "storage"
						}
						if #component.metadata.annotations != _|_ {
							annotations: #component.metadata.annotations
						}
					}
					spec: {
						accessModes: volume.accessModes | *["ReadWriteOnce"]
						resources: {
							requests: {
								storage: volume.size
							}
						}

						if volume.storageClass != _|_ {
							storageClassName: volume.storageClass
						}

						if volume.volumeMode != _|_ {
							volumeMode: volume.volumeMode
						}

						if volume.selector != _|_ {
							selector: volume.selector
						}
					}
				}
			}
		}
	}
}
