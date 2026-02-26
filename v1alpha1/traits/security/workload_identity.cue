package security

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// WorkloadIdentity Trait Definition
/////////////////////////////////////////////////////////////////

#WorkloadIdentityTrait: core.#Trait & {
	metadata: {
		modulePath: "opmodel.dev/traits/security@v1"
		name:          "workload-identity"
		description:   "A workload identity definition for service identity"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #WorkloadIdentityDefaults

	spec: close({workloadIdentity: schemas.#WorkloadIdentitySchema})
}

#WorkloadIdentity: core.#Component & {
	#traits: {(#WorkloadIdentityTrait.metadata.fqn): #WorkloadIdentityTrait}
}

#WorkloadIdentityDefaults: schemas.#WorkloadIdentitySchema & {
	automountToken: false
}
