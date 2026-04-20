package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VirtualDiskTransformer passes native ch-vmm VirtualDisk resources through
// with OPM context applied (name prefix, namespace, labels).
#VirtualDiskTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "virtual-disk-transformer"
		description: "Passes native ch-vmm VirtualDisk resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "virtual-disk"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VirtualDiskResource.metadata.fqn): res.#VirtualDiskResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vd:   #component.spec.virtualDisk
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VirtualDisk"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vd.metadata != _|_ {
					if _vd.metadata.annotations != _|_ {
						annotations: _vd.metadata.annotations
					}
				}
			}
			if _vd.spec != _|_ {
				spec: _vd.spec
			}
		}
	}
}
