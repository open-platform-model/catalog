package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vmm "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/virtualmachinemigration/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VirtualMachineMigration Resource Definition
/////////////////////////////////////////////////////////////////

#VirtualMachineMigrationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "virtual-machine-migration"
		description: "A ch-vmm VirtualMachineMigration (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VirtualMachineMigrationDefaults

	spec: close({virtualMachineMigration: {
		metadata?: _#metadata
		spec?:     vmm.#VirtualMachineMigrationSpec
	}})
}

#VirtualMachineMigration: component.#Component & {
	#resources: {(#VirtualMachineMigrationResource.metadata.fqn): #VirtualMachineMigrationResource}
}

#VirtualMachineMigrationDefaults: {
	metadata?: _#metadata
	spec?:     vmm.#VirtualMachineMigrationSpec
}
