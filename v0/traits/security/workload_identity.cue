package security

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// WorkloadIdentity Trait Definition
/////////////////////////////////////////////////////////////////

#WorkloadIdentityTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/security@v0"
		name:        "workload-identity"
		description: "A workload identity definition for service identity"
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for WorkloadIdentity trait
	#defaults: #WorkloadIdentityDefaults

	// OpenAPIv3-compatible schema defining the structure of the WorkloadIdentity spec
	#spec: workloadIdentity: schemas.#WorkloadIdentitySchema
}

#WorkloadIdentity: core.#Component & {
	#traits: {(#WorkloadIdentityTrait.metadata.fqn): #WorkloadIdentityTrait}
}

#WorkloadIdentityDefaults: schemas.#WorkloadIdentitySchema & {
	automountToken: false
}
