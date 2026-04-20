package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vmp "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/vmpool/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VMPool Resource Definition
/////////////////////////////////////////////////////////////////

#VMPoolResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "vm-pool"
		description: "A ch-vmm VMPool (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VMPoolDefaults

	spec: close({vmPool: {
		metadata?: _#metadata
		spec?:     vmp.#VMPoolSpec
	}})
}

#VMPool: component.#Component & {
	#resources: {(#VMPoolResource.metadata.fqn): #VMPoolResource}
}

#VMPoolDefaults: {
	metadata?: _#metadata
	spec?:     vmp.#VMPoolSpec
}
