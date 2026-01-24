package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// HealthCheck Trait Definition
/////////////////////////////////////////////////////////////////

#HealthCheckTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v0"
		name:        "HealthCheck"
		description: "A trait to specify liveness and readiness probes for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	// Default values for health check trait
	#defaults: #HealthCheckDefaults

	#spec: healthCheck: schemas.#HealthCheckSchema
})

#HealthCheck: close(core.#ComponentDefinition & {
	#traits: {(#HealthCheckTrait.metadata.fqn): #HealthCheckTrait}
})

#HealthCheckDefaults: close(schemas.#HealthCheckSchema & {})
