package workload

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vmrs "opmodel.dev/ch_vmm/v1alpha1/schemas/ch-vmm/cloudhypervisor.quill.today/vmrestorespec/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// VMRestoreSpec Resource Definition
/////////////////////////////////////////////////////////////////

#VMRestoreSpecResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/resources/workload"
		version:     "v1"
		name:        "vm-restore-spec"
		description: "A ch-vmm VMRestoreSpec (cloudhypervisor.quill.today/v1beta1)"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	#defaults: #VMRestoreSpecDefaults

	spec: close({vmRestoreSpec: {
		metadata?: _#metadata
		spec?:     vmrs.#VMRestoreSpecSpec
	}})
}

#VMRestoreSpec: component.#Component & {
	#resources: {(#VMRestoreSpecResource.metadata.fqn): #VMRestoreSpecResource}
}

#VMRestoreSpecDefaults: {
	metadata?: _#metadata
	spec?:     vmrs.#VMRestoreSpecSpec
}
