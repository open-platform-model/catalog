package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vmsn "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/vmsnapshot/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VMSnapShot Resource Definition
/////////////////////////////////////////////////////////////////

#VMSnapShotResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "vm-snap-shot"
		description: "A ch-vmm VMSnapShot (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VMSnapShotDefaults

	spec: close({vmSnapShot: {
		metadata?: _#metadata
		spec?:     vmsn.#VMSnapShotSpec
	}})
}

#VMSnapShot: component.#Component & {
	#resources: {(#VMSnapShotResource.metadata.fqn): #VMSnapShotResource}
}

#VMSnapShotDefaults: {
	metadata?: _#metadata
	spec?:     vmsn.#VMSnapShotSpec
}
