package security

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// WorkloadIdentity Trait Definition
/////////////////////////////////////////////////////////////////

#WorkloadIdentityTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/security"
		version:     "v1"
		name:        "workload-identity"
		description: "A workload identity definition for service identity"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #WorkloadIdentityDefaults

	spec: close({workloadIdentity: schemas.#WorkloadIdentitySchema})
}

#WorkloadIdentity: component.#Component & {
	#traits: {(#WorkloadIdentityTrait.metadata.fqn): #WorkloadIdentityTrait}
}

#WorkloadIdentityDefaults: schemas.#WorkloadIdentitySchema & {
	automountToken: false
}
