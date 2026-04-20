package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vmrb "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/vmrollback/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VMRollback Resource Definition
/////////////////////////////////////////////////////////////////

#VMRollbackResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "vm-rollback"
		description: "A ch-vmm VMRollback (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VMRollbackDefaults

	spec: close({vmRollback: {
		metadata?: _#metadata
		spec?:     vmrb.#VMRollbackSpec
	}})
}

#VMRollback: component.#Component & {
	#resources: {(#VMRollbackResource.metadata.fqn): #VMRollbackResource}
}

#VMRollbackDefaults: {
	metadata?: _#metadata
	spec?:     vmrb.#VMRollbackSpec
}
