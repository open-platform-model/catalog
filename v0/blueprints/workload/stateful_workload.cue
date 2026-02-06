package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
)

/////////////////////////////////////////////////////////////////
//// StatefulWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#StatefulWorkloadBlueprint: close(core.#Blueprint & {
	metadata: {
		apiVersion:  "opmodel.dev/blueprints/core@v0"
		name:        "stateful-workload"
		description: "A stateful workload with stable identity and persistent storage requirements"
		labels: {
			"core.opmodel.dev/category":      "workload"
			"core.opmodel.dev/workload-type": "stateful"
		}
	}

	composedResources: [
		workload_resources.#ContainerResource,
		storage_resources.#VolumeResource,
	]

	composedTraits: [
		workload_traits.#ReplicasTrait,
		workload_traits.#RestartPolicyTrait,
		workload_traits.#UpdateStrategyTrait,
		workload_traits.#HealthCheckTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: statefulWorkload: schemas.#StatefulWorkloadSchema
})

#StatefulWorkload: close(core.#Component & {
	#blueprints: (#StatefulWorkloadBlueprint.metadata.fqn): #StatefulWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#Replicas
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers
	storage_resources.#Volumes

	#spec: {
		statefulWorkload: schemas.#StatefulWorkloadSchema
		container:        statefulWorkload.container
		if statefulWorkload.replicas != _|_ {
			replicas: statefulWorkload.replicas
		}
		if statefulWorkload.restartPolicy != _|_ {
			restartPolicy: statefulWorkload.restartPolicy
		}
		if statefulWorkload.updateStrategy != _|_ {
			updateStrategy: statefulWorkload.updateStrategy
		}
		if statefulWorkload.healthCheck != _|_ {
			healthCheck: statefulWorkload.healthCheck
		}
		if statefulWorkload.sidecarContainers != _|_ {
			sidecarContainers: statefulWorkload.sidecarContainers
		}
		if statefulWorkload.initContainers != _|_ {
			initContainers: statefulWorkload.initContainers
		}
		if statefulWorkload.volumes != _|_ {
			volumes: statefulWorkload.volumes
		}
	}
})
