package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// TaskWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#TaskWorkloadBlueprint: close(core.#Blueprint & {
	metadata: {
		apiVersion:  "opmodel.dev/blueprints/workload@v0"
		name:        "task-workload"
		description: "A one-time task workload that runs to completion (Job)"
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#JobConfigTrait,
		workload_traits.#RestartPolicyTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: taskWorkload: schemas.#TaskWorkloadSchema
})

#TaskWorkload: close(core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "task"
	}

	#blueprints: (#TaskWorkloadBlueprint.metadata.fqn): #TaskWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#RestartPolicy
	workload_traits.#JobConfig
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		taskWorkload: schemas.#TaskWorkloadSchema
		container:    taskWorkload.container
		if taskWorkload.restartPolicy != _|_ {
			restartPolicy: taskWorkload.restartPolicy
		}
		if taskWorkload.jobConfig != _|_ {
			jobConfig: taskWorkload.jobConfig
		}
		if taskWorkload.sidecarContainers != _|_ {
			sidecarContainers: taskWorkload.sidecarContainers
		}
		if taskWorkload.initContainers != _|_ {
			initContainers: taskWorkload.initContainers
		}
	}

	// Override spec to propagate values from taskWorkload
	spec: {
		container: spec.taskWorkload.container
		if spec.taskWorkload.restartPolicy != _|_ {
			restartPolicy: spec.taskWorkload.restartPolicy
		}
		if spec.taskWorkload.jobConfig != _|_ {
			jobConfig: spec.taskWorkload.jobConfig
		}
		if spec.taskWorkload.sidecarContainers != _|_ {
			sidecarContainers: spec.taskWorkload.sidecarContainers
		}
		if spec.taskWorkload.initContainers != _|_ {
			initContainers: spec.taskWorkload.initContainers
		}
	}
})
