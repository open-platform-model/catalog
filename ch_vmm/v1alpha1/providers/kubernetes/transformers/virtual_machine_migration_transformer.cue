package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VirtualMachineMigrationTransformer passes native ch-vmm VirtualMachineMigration resources through
// with OPM context applied (name prefix, namespace, labels).
#VirtualMachineMigrationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "virtual-machine-migration-transformer"
		description: "Passes native ch-vmm VirtualMachineMigration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "virtual-machine-migration"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VirtualMachineMigrationResource.metadata.fqn): res.#VirtualMachineMigrationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vmm:  #component.spec.virtualMachineMigration
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VirtualMachineMigration"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vmm.metadata != _|_ {
					if _vmm.metadata.annotations != _|_ {
						annotations: _vmm.metadata.annotations
					}
				}
			}
			if _vmm.spec != _|_ {
				spec: _vmm.spec
			}
		}
	}
}
