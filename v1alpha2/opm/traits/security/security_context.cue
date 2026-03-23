package security

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// SecurityContext Trait Definition
/////////////////////////////////////////////////////////////////

#SecurityContextTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/security"
		version:     "v1"
		name:        "security-context"
		description: "Container and pod-level security constraints"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #SecurityContextDefaults

	spec: close({securityContext: schemas.#SecurityContextSchema})
}

#SecurityContext: component.#Component & {
	#traits: {(#SecurityContextTrait.metadata.fqn): #SecurityContextTrait}
}

#SecurityContextDefaults: schemas.#SecurityContextSchema & {
	runAsNonRoot:             true
	allowPrivilegeEscalation: false
}
