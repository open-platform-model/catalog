package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vd "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/virtualdisk/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VirtualDisk Resource Definition
/////////////////////////////////////////////////////////////////

#VirtualDiskResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "virtual-disk"
		description: "A ch-vmm VirtualDisk (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VirtualDiskDefaults

	spec: close({virtualDisk: {
		metadata?: _#metadata
		spec?:     vd.#VirtualDiskSpec
	}})
}

#VirtualDisk: component.#Component & {
	#resources: {(#VirtualDiskResource.metadata.fqn): #VirtualDiskResource}
}

#VirtualDiskDefaults: {
	metadata?: _#metadata
	spec?:     vd.#VirtualDiskSpec
}
