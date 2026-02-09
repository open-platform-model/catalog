package security

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
)

/////////////////////////////////////////////////////////////////
//// SecurityContext Trait Definition
/////////////////////////////////////////////////////////////////

#SecurityContextTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/security@v0"
		name:        "security-context"
		description: "Container and pod-level security constraints"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #SecurityContextDefaults

	#spec: securityContext: schemas.#SecurityContextSchema
})

#SecurityContext: close(core.#Component & {
	#traits: {(#SecurityContextTrait.metadata.fqn): #SecurityContextTrait}
})

#SecurityContextDefaults: close(schemas.#SecurityContextSchema & {
	runAsNonRoot:             true
	allowPrivilegeEscalation: false
})
