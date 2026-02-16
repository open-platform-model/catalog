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
		apiVersion:  "opmodel.dev/blueprints/workload@v0"
		name:        "stateful-workload"
		description: "A stateful workload with stable identity and persistent storage requirements"
	}

	composedResources: [
		workload_resources.#ContainerResource,
		storage_resources.#VolumeResource,
	]

	composedTraits: [
		workload_traits.#ScalingTrait,
		workload_traits.#RestartPolicyTrait,
		workload_traits.#UpdateStrategyTrait,
		workload_traits.#HealthCheckTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: statefulWorkload: schemas.#StatefulWorkloadSchema
})

#StatefulWorkload: close(core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "stateful"
	}

	#blueprints: (#StatefulWorkloadBlueprint.metadata.fqn): #StatefulWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#Scaling
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers
	storage_resources.#Volumes

	#spec: {
		statefulWorkload: schemas.#StatefulWorkloadSchema
		container:        statefulWorkload.container
		if statefulWorkload.scaling != _|_ {
			scaling: statefulWorkload.scaling
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

	// Override spec to propagate values from statefulWorkload
	spec: {
		container: spec.statefulWorkload.container
		if spec.statefulWorkload.scaling != _|_ {
			scaling: spec.statefulWorkload.scaling
		}
		if spec.statefulWorkload.restartPolicy != _|_ {
			restartPolicy: spec.statefulWorkload.restartPolicy
		}
		if spec.statefulWorkload.updateStrategy != _|_ {
			updateStrategy: spec.statefulWorkload.updateStrategy
		}
		if spec.statefulWorkload.healthCheck != _|_ {
			healthCheck: spec.statefulWorkload.healthCheck
		}
		if spec.statefulWorkload.sidecarContainers != _|_ {
			sidecarContainers: spec.statefulWorkload.sidecarContainers
		}
		if spec.statefulWorkload.initContainers != _|_ {
			initContainers: spec.statefulWorkload.initContainers
		}
		if spec.statefulWorkload.volumes != _|_ {
			volumes: spec.statefulWorkload.volumes
		}
	}
})
