package workload

import (
	prim "opmodel.dev/opm/core/primitives@v1"
	component "opmodel.dev/opm/core/component@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	workload_resources "opmodel.dev/opm/resources/workload@v1"
	workload_traits "opmodel.dev/opm/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// DaemonWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#DaemonWorkloadBlueprint: prim.#Blueprint & {
	metadata: {
		modulePath:  "opmodel.dev/opm/blueprints/workload"
		version:     "v1"
		name:        "daemon-workload"
		description: "A daemon workload that runs on all (or selected) nodes in a cluster"
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#RestartPolicyTrait,
		workload_traits.#UpdateStrategyTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	spec: daemonWorkload: schemas.#DaemonWorkloadSchema
}

#DaemonWorkload: component.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "daemon"
	}

	#blueprints: (#DaemonWorkloadBlueprint.metadata.fqn): #DaemonWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	// Override spec to propagate values from daemonWorkload
	spec: {
		daemonWorkload: schemas.#DaemonWorkloadSchema
		container:      daemonWorkload.container
		if daemonWorkload.restartPolicy != _|_ {
			restartPolicy: daemonWorkload.restartPolicy
		}
		if daemonWorkload.updateStrategy != _|_ {
			updateStrategy: daemonWorkload.updateStrategy
		}
		if daemonWorkload.sidecarContainers != _|_ {
			sidecarContainers: daemonWorkload.sidecarContainers
		}
		if daemonWorkload.initContainers != _|_ {
			initContainers: daemonWorkload.initContainers
		}
	}
}
