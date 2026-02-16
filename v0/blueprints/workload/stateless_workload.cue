package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// StatelessWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#StatelessWorkloadBlueprint: close(core.#Blueprint & {
	metadata: {
		apiVersion:  "opmodel.dev/blueprints/workload@v0"
		name:        "stateless-workload"
		description: "A stateless workload with no requirement for stable identity or storage"
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#ScalingTrait,
	]

	#spec: statelessWorkload: schemas.#StatelessWorkloadSchema
})

#StatelessWorkload: close(core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "stateless"
	}

	#blueprints: (#StatelessWorkloadBlueprint.metadata.fqn): #StatelessWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#Scaling
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		statelessWorkload: schemas.#StatelessWorkloadSchema
		container:         statelessWorkload.container
		if statelessWorkload.scaling != _|_ {
			scaling: statelessWorkload.scaling
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

	// Override spec to propagate values from statelessWorkload
	spec: {
		container: spec.statelessWorkload.container
		if spec.statelessWorkload.scaling != _|_ {
			scaling: spec.statelessWorkload.scaling
		}
		if spec.statelessWorkload.restartPolicy != _|_ {
			restartPolicy: spec.statelessWorkload.restartPolicy
		}
		if spec.statelessWorkload.updateStrategy != _|_ {
			updateStrategy: spec.statelessWorkload.updateStrategy
		}
		if spec.statelessWorkload.healthCheck != _|_ {
			healthCheck: spec.statelessWorkload.healthCheck
		}
		if spec.statelessWorkload.sidecarContainers != _|_ {
			sidecarContainers: spec.statelessWorkload.sidecarContainers
		}
		if spec.statelessWorkload.initContainers != _|_ {
			initContainers: spec.statelessWorkload.initContainers
		}
	}
})
