package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VMPoolTransformer passes native ch-vmm VMPool resources through
// with OPM context applied (name prefix, namespace, labels).
#VMPoolTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "vm-pool-transformer"
		description: "Passes native ch-vmm VMPool resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "vm-pool"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VMPoolResource.metadata.fqn): res.#VMPoolResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vmp:  #component.spec.vmPool
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VMPool"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vmp.metadata != _|_ {
					if _vmp.metadata.annotations != _|_ {
						annotations: _vmp.metadata.annotations
					}
				}
			}
			if _vmp.spec != _|_ {
				spec: _vmp.spec
			}
		}
	}
}
