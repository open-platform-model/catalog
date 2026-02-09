package workload

import (
	core "example.com/config-sources/core"
	schemas "example.com/config-sources/schemas"
	workload_resources "example.com/config-sources/resources/workload"
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
