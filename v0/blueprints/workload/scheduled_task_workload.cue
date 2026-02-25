package workload

import (
	core "opmodel.dev/core@v0"
	schemas "opmodel.dev/schemas@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
)

/////////////////////////////////////////////////////////////////
//// ScheduledTaskWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#ScheduledTaskWorkloadBlueprint: core.#Blueprint & {
	metadata: {
		apiVersion:  "opmodel.dev/blueprints/workload@v0"
		name:        "scheduled-task-workload"
		description: "A scheduled task workload that runs on a cron schedule (CronJob)"
	}

	composedResources: [
		workload_resources.#ContainerResource,
	]

	composedTraits: [
		workload_traits.#CronJobConfigTrait,
		workload_traits.#RestartPolicyTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: scheduledTaskWorkload: schemas.#ScheduledTaskWorkloadSchema
}

#ScheduledTaskWorkload: core.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "scheduled-task"
	}

	#blueprints: (#ScheduledTaskWorkloadBlueprint.metadata.fqn): #ScheduledTaskWorkloadBlueprint

	workload_resources.#Container
	workload_traits.#RestartPolicy
	workload_traits.#CronJobConfig
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		scheduledTaskWorkload: schemas.#ScheduledTaskWorkloadSchema
		container:             scheduledTaskWorkload.container
		if scheduledTaskWorkload.restartPolicy != _|_ {
			restartPolicy: scheduledTaskWorkload.restartPolicy
		}
		cronJobConfig: scheduledTaskWorkload.cronJobConfig
		if scheduledTaskWorkload.sidecarContainers != _|_ {
			sidecarContainers: scheduledTaskWorkload.sidecarContainers
		}
		if scheduledTaskWorkload.initContainers != _|_ {
			initContainers: scheduledTaskWorkload.initContainers
		}
	}

	// Override spec to propagate values from scheduledTaskWorkload
	spec: {
		container: spec.scheduledTaskWorkload.container
		if spec.scheduledTaskWorkload.restartPolicy != _|_ {
			restartPolicy: spec.scheduledTaskWorkload.restartPolicy
		}
		cronJobConfig: spec.scheduledTaskWorkload.cronJobConfig
		if spec.scheduledTaskWorkload.sidecarContainers != _|_ {
			sidecarContainers: spec.scheduledTaskWorkload.sidecarContainers
		}
		if spec.scheduledTaskWorkload.initContainers != _|_ {
			initContainers: spec.scheduledTaskWorkload.initContainers
		}
	}
}
