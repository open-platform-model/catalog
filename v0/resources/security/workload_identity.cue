package security

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
)

/////////////////////////////////////////////////////////////////
//// WorkloadIdentity Resource Definition
/////////////////////////////////////////////////////////////////

#WorkloadIdentityResource: close(core.#Resource & {
	metadata: {
		apiVersion:  "opmodel.dev/resources/security@v0"
		name:        "workload-identity"
		description: "A workload identity definition for service identity"
		labels: {}
	}

	// Default values for WorkloadIdentity resource
	#defaults: #WorkloadIdentityDefaults

	// OpenAPIv3-compatible schema defining the structure of the WorkloadIdentity spec
	#spec: workloadIdentity: schemas.#WorkloadIdentitySchema
})

#WorkloadIdentity: close(core.#Component & {
	#resources: {(#WorkloadIdentityResource.metadata.fqn): #WorkloadIdentityResource}
})

#WorkloadIdentityDefaults: close(schemas.#WorkloadIdentitySchema & {
	automountToken: false
})
