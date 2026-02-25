package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// DaemonWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#DaemonWorkloadBlueprint: core.#Blueprint & {
	metadata: {
		apiVersion:  "opmodel.dev/blueprints/workload@v0"
		name:        "daemon-workload"
		description: "A daemon workload that runs on all (or selected) nodes in a cluster"
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#RestartPolicyTrait,
		workload_traits.#UpdateStrategyTrait,
		workload_traits.#HealthCheckTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: daemonWorkload: schemas.#DaemonWorkloadSchema
}

#DaemonWorkload: core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "daemon"
	}

	#blueprints: (#DaemonWorkloadBlueprint.metadata.fqn): #DaemonWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		daemonWorkload: schemas.#DaemonWorkloadSchema
		container:      daemonWorkload.container
		if daemonWorkload.restartPolicy != _|_ {
			restartPolicy: daemonWorkload.restartPolicy
		}
		if daemonWorkload.updateStrategy != _|_ {
			updateStrategy: daemonWorkload.updateStrategy
		}
		if daemonWorkload.healthCheck != _|_ {
			healthCheck: daemonWorkload.healthCheck
		}
		if daemonWorkload.sidecarContainers != _|_ {
			sidecarContainers: daemonWorkload.sidecarContainers
		}
		if daemonWorkload.initContainers != _|_ {
			initContainers: daemonWorkload.initContainers
		}
	}

	// Override spec to propagate values from daemonWorkload
	spec: {
		container: spec.daemonWorkload.container
		if spec.daemonWorkload.restartPolicy != _|_ {
			restartPolicy: spec.daemonWorkload.restartPolicy
		}
		if spec.daemonWorkload.updateStrategy != _|_ {
			updateStrategy: spec.daemonWorkload.updateStrategy
		}
		if spec.daemonWorkload.healthCheck != _|_ {
			healthCheck: spec.daemonWorkload.healthCheck
		}
		if spec.daemonWorkload.sidecarContainers != _|_ {
			sidecarContainers: spec.daemonWorkload.sidecarContainers
		}
		if spec.daemonWorkload.initContainers != _|_ {
			initContainers: spec.daemonWorkload.initContainers
		}
	}
}
