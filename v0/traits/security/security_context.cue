package security

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// SecurityContext Trait Definition
/////////////////////////////////////////////////////////////////

#SecurityContextTrait: core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/security@v0"
		name:        "security-context"
		description: "Container and pod-level security constraints"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #SecurityContextDefaults

	#spec: securityContext: schemas.#SecurityContextSchema
}

#SecurityContext: core.#Component & {
	#traits: {(#SecurityContextTrait.metadata.fqn): #SecurityContextTrait}
}

#SecurityContextDefaults: schemas.#SecurityContextSchema & {
	runAsNonRoot:             true
	allowPrivilegeEscalation: false
}
