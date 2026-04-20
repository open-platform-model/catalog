package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vms "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/vmset/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VMSet Resource Definition
/////////////////////////////////////////////////////////////////

#VMSetResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "vm-set"
		description: "A ch-vmm VMSet (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VMSetDefaults

	spec: close({vmSet: {
		metadata?: _#metadata
		spec?:     vms.#VMSetSpec
	}})
}

#VMSet: component.#Component & {
	#resources: {(#VMSetResource.metadata.fqn): #VMSetResource}
}

#VMSetDefaults: {
	metadata?: _#metadata
	spec?:     vms.#VMSetSpec
}
