package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VMSetTransformer passes native ch-vmm VMSet resources through
// with OPM context applied (name prefix, namespace, labels).
#VMSetTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "vm-set-transformer"
		description: "Passes native ch-vmm VMSet resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "vm-set"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VMSetResource.metadata.fqn): res.#VMSetResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vms:  #component.spec.vmSet
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VMSet"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vms.metadata != _|_ {
					if _vms.metadata.annotations != _|_ {
						annotations: _vms.metadata.annotations
					}
				}
			}
			if _vms.spec != _|_ {
				spec: _vms.spec
			}
		}
	}
}
