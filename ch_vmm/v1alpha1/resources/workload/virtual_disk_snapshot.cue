package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vds "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/virtualdisksnapshot/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VirtualDiskSnapshot Resource Definition
/////////////////////////////////////////////////////////////////

#VirtualDiskSnapshotResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "virtual-disk-snapshot"
		description: "A ch-vmm VirtualDiskSnapshot (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VirtualDiskSnapshotDefaults

	spec: close({virtualDiskSnapshot: {
		metadata?: _#metadata
		spec?:     vds.#VirtualDiskSnapshotSpec
	}})
}

#VirtualDiskSnapshot: component.#Component & {
	#resources: {(#VirtualDiskSnapshotResource.metadata.fqn): #VirtualDiskSnapshotResource}
}

#VirtualDiskSnapshotDefaults: {
	metadata?: _#metadata
	spec?:     vds.#VirtualDiskSnapshotSpec
}
