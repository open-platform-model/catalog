package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/storage@v1"
)

// #PersistentVolumeClaimTransformer passes native Kubernetes PVC resources through
// with OPM context applied (name prefix, namespace, labels).
#PersistentVolumeClaimTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "persistentvolumeclaim-transformer"
		description: "Passes native Kubernetes PersistentVolumeClaim resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolumeclaim"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PersistentVolumeClaimResource.metadata.fqn): res.#PersistentVolumeClaimResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_pvc:  #component.spec.persistentvolumeclaim
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _pvc.metadata != _|_ {
					if _pvc.metadata.annotations != _|_ {
						annotations: _pvc.metadata.annotations
					}
				}
			}
			if _pvc.spec != _|_ {
				spec: _pvc.spec
			}
		}
	}
}
