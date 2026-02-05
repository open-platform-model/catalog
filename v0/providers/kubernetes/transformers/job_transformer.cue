package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	"list"
)

// JobTransformer converts task workload components to Kubernetes Jobs
#JobTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v1"
		name:        "JobTransformer"
		description: "Converts task workload components to Kubernetes Jobs"

		labels: {
			"core.opmodel.dev/workload-type": "task"
			"core.opmodel.dev/resource-type": "job"
		}
	}

	// Required label to match task workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "task"
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - JobConfig is mandatory for Job
	requiredTraits: {
		"opmodel.dev/traits/workload@v0#JobConfig": workload_traits.#JobConfigTrait
	}

	// Optional traits
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#SidecarContainers": workload_traits.#SidecarContainersTrait
		"opmodel.dev/traits/workload@v0#InitContainers":    workload_traits.#InitContainersTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Extract required JobConfig trait (will be bottom if not present)
		_jobConfig: #component.spec.jobConfig

		// Apply defaults for optional RestartPolicy trait
		// For Jobs, default restart policy should be "OnFailure" or "Never", not "Always"
		_restartPolicy: *"OnFailure" | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Extract optional sidecar and init containers with defaults
		_sidecarContainers: *optionalTraits["opmodel.dev/traits/workload@v0#SidecarContainers"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_initContainers: *optionalTraits["opmodel.dev/traits/workload@v0#InitContainers"].#defaults | [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		output: {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace | *"default"
				labels: #context.labels
				if #component.metadata.annotations != _|_ {
					annotations: #component.metadata.annotations
				}
			}
			spec: {
				completions: *requiredTraits["opmodel.dev/traits/workload@v0#JobConfig"].#defaults.completions | int
				if _jobConfig.completions != _|_ {
					completions: _jobConfig.completions
				}

				parallelism: *requiredTraits["opmodel.dev/traits/workload@v0#JobConfig"].#defaults.parallelism | int
				if _jobConfig.parallelism != _|_ {
					parallelism: _jobConfig.parallelism
				}

				backoffLimit: *requiredTraits["opmodel.dev/traits/workload@v0#JobConfig"].#defaults.backoffLimit | int
				if _jobConfig.backoffLimit != _|_ {
					backoffLimit: _jobConfig.backoffLimit
				}

				activeDeadlineSeconds: *requiredTraits["opmodel.dev/traits/workload@v0#JobConfig"].#defaults.activeDeadlineSeconds | int
				if _jobConfig.activeDeadlineSeconds != _|_ {
					activeDeadlineSeconds: _jobConfig.activeDeadlineSeconds
				}

				ttlSecondsAfterFinished: *requiredTraits["opmodel.dev/traits/workload@v0#JobConfig"].#defaults.ttlSecondsAfterFinished | int
				if _jobConfig.ttlSecondsAfterFinished != _|_ {
					ttlSecondsAfterFinished: _jobConfig.ttlSecondsAfterFinished
				}

				template: {
					metadata: labels: #context.componentLabels
					spec: {
						containers: list.Concat([[_container], _sidecarContainers])

						if len(_initContainers) > 0 {
							initContainers: _initContainers
						}

						restartPolicy: _restartPolicy
					}
				}
			}
		}
	}
}

_testJobTransformer: #JobTransformer.#transform & {
	#component: _testJobComponent
	#context:   _testContext
}
