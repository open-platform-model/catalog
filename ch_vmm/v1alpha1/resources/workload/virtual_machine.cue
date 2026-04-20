package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vm "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/virtualmachine/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VirtualMachine Resource Definition
/////////////////////////////////////////////////////////////////

#VirtualMachineResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "virtual-machine"
		description: "A ch-vmm VirtualMachine (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VirtualMachineDefaults

	spec: close({virtualMachine: {
		metadata?: _#metadata
		spec?:     vm.#VirtualMachineSpec
	}})
}

#VirtualMachine: component.#Component & {
	#resources: {(#VirtualMachineResource.metadata.fqn): #VirtualMachineResource}
}

#VirtualMachineDefaults: {
	metadata?: _#metadata
	spec?:     vm.#VirtualMachineSpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
