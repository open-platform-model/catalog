package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// GracefulShutdown Trait Definition
/////////////////////////////////////////////////////////////////

#GracefulShutdownTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "graceful-shutdown"
		description: "Termination grace period and pre-stop lifecycle hooks"
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: #GracefulShutdownDefaults

	#spec: gracefulShutdown: schemas.#GracefulShutdownSchema
})

#GracefulShutdown: close(core.#Component & {
	#traits: {(#GracefulShutdownTrait.metadata.fqn): #GracefulShutdownTrait}
})

#GracefulShutdownDefaults: close(schemas.#GracefulShutdownSchema & {
	terminationGracePeriodSeconds: 30
})
