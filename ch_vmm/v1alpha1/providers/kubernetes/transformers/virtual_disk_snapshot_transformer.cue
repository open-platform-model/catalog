package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VirtualDiskSnapshotTransformer passes native ch-vmm VirtualDiskSnapshot resources through
// with OPM context applied (name prefix, namespace, labels).
#VirtualDiskSnapshotTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "virtual-disk-snapshot-transformer"
		description: "Passes native ch-vmm VirtualDiskSnapshot resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "virtual-disk-snapshot"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VirtualDiskSnapshotResource.metadata.fqn): res.#VirtualDiskSnapshotResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vds:  #component.spec.virtualDiskSnapshot
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VirtualDiskSnapshot"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vds.metadata != _|_ {
					if _vds.metadata.annotations != _|_ {
						annotations: _vds.metadata.annotations
					}
				}
			}
			if _vds.spec != _|_ {
				spec: _vds.spec
			}
		}
	}
}
