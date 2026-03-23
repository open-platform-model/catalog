package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// GracefulShutdown Trait Definition
/////////////////////////////////////////////////////////////////

#GracefulShutdownTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/traits/workload"
		version:     "v1"
		name:        "graceful-shutdown"
		description: "Termination grace period and pre-stop lifecycle hooks"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #GracefulShutdownDefaults

	spec: close({gracefulShutdown: schemas.#GracefulShutdownSchema})
}

#GracefulShutdown: component.#Component & {
	#traits: {(#GracefulShutdownTrait.metadata.fqn): #GracefulShutdownTrait}
}

#GracefulShutdownDefaults: schemas.#GracefulShutdownSchema & {
	terminationGracePeriodSeconds: 30
}
