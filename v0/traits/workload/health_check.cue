package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// HealthCheck Trait Definition
/////////////////////////////////////////////////////////////////

#HealthCheckTrait: close(core.#Trait & {
	metadata: {
		apiVersion:  "opmodel.dev/traits/workload@v0"
		name:        "health-check"
		description: "A trait to specify liveness and readiness probes for a workload"
		labels: {
			"core.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for health check trait
	#defaults: #HealthCheckDefaults

	#spec: healthCheck: schemas.#HealthCheckSchema
})

#HealthCheck: close(core.#Component & {
	#traits: {(#HealthCheckTrait.metadata.fqn): #HealthCheckTrait}
})

#HealthCheckDefaults: close(schemas.#HealthCheckSchema & {})
