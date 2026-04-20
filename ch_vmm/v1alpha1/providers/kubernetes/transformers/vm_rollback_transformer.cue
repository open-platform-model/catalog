package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VMRollbackTransformer passes native ch-vmm VMRollback resources through
// with OPM context applied (name prefix, namespace, labels).
#VMRollbackTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "vm-rollback-transformer"
		description: "Passes native ch-vmm VMRollback resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "vm-rollback"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VMRollbackResource.metadata.fqn): res.#VMRollbackResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vmrb: #component.spec.vmRollback
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VMRollback"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vmrb.metadata != _|_ {
					if _vmrb.metadata.annotations != _|_ {
						annotations: _vmrb.metadata.annotations
					}
				}
			}
			if _vmrb.spec != _|_ {
				spec: _vmrb.spec
			}
		}
	}
}
