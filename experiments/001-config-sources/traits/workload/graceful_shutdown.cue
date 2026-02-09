package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
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
