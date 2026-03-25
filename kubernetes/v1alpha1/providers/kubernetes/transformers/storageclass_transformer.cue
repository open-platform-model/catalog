package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/storage@v1"
)

// #StorageClassTransformer passes native Kubernetes StorageClass resources through
// with OPM context applied (name prefix, labels). StorageClass is cluster-scoped: no namespace.
#StorageClassTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "storageclass-transformer"
		description: "Passes native Kubernetes StorageClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "storageclass"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#StorageClassResource.metadata.fqn): res.#StorageClassResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_sc:   #component.spec.storageclass
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "storage.k8s.io/v1"
			kind:       "StorageClass"
			metadata: {
				name:   _name
				labels: #context.labels
				if _sc.metadata != _|_ {
					if _sc.metadata.annotations != _|_ {
						annotations: _sc.metadata.annotations
					}
				}
			}
			provisioner: _sc.provisioner
			if _sc.reclaimPolicy != _|_ {
				reclaimPolicy: _sc.reclaimPolicy
			}
			if _sc.volumeBindingMode != _|_ {
				volumeBindingMode: _sc.volumeBindingMode
			}
			if _sc.parameters != _|_ {
				parameters: _sc.parameters
			}
			if _sc.allowVolumeExpansion != _|_ {
				allowVolumeExpansion: _sc.allowVolumeExpansion
			}
			if _sc.mountOptions != _|_ {
				mountOptions: _sc.mountOptions
			}
		}
	}
}
