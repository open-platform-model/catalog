package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/storage@v1"
)

// #PersistentVolumeTransformer passes native Kubernetes PV resources through
// with OPM context applied (name prefix, labels). PV is cluster-scoped: no namespace.
#PersistentVolumeTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "persistentvolume-transformer"
		description: "Passes native Kubernetes PersistentVolume resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolume"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PersistentVolumeResource.metadata.fqn): res.#PersistentVolumeResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_pv:   #component.spec.persistentvolume
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "PersistentVolume"
			metadata: {
				name:   _name
				labels: #context.labels
				if _pv.metadata != _|_ {
					if _pv.metadata.annotations != _|_ {
						annotations: _pv.metadata.annotations
					}
				}
			}
			if _pv.spec != _|_ {
				spec: _pv.spec
			}
		}
	}
}
