package workload

import (
	core "opm.dev/core@v0"
	schemas "opm.dev/schemas@v0"
	workload_resources "opm.dev/resources/workload@v0"
	workload_traits "opm.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// StatelessWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#StatelessWorkloadBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v0"
		name:        "StatelessWorkload"
		description: "A stateless workload with no requirement for stable identity or storage"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "stateless"
		}
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#ReplicasTrait,
	]

	#spec: statelessWorkload: schemas.#StatelessWorkloadSchema
})

#StatelessWorkload: close(core.#ComponentDefinition & {
	#blueprints: (#StatelessWorkloadBlueprint.metadata.fqn): #StatelessWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#Replicas
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		statelessWorkload: schemas.#StatelessWorkloadSchema
		container:         statelessWorkload.container
		if statelessWorkload.replicas != _|_ {
			replicas: statelessWorkload.replicas
		}
		if statelessWorkload.restartPolicy != _|_ {
			restartPolicy: statelessWorkload.restartPolicy
		}
		if statelessWorkload.updateStrategy != _|_ {
			updateStrategy: statelessWorkload.updateStrategy
		}
		if statelessWorkload.healthCheck != _|_ {
			healthCheck: statelessWorkload.healthCheck
		}
		if statelessWorkload.sidecarContainers != _|_ {
			sidecarContainers: statelessWorkload.sidecarContainers
		}
		if statelessWorkload.initContainers != _|_ {
			initContainers: statelessWorkload.initContainers
		}
	}
})
