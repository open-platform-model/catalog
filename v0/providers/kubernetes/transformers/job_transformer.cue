package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	security_traits "opmodel.dev/traits/security@v0"
	security_resources "opmodel.dev/resources/security@v0"
	"list"
)

// JobTransformer converts task workload components to Kubernetes Jobs
#JobTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "job-transformer"
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

	// Optional resources
	optionalResources: {
		"opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource
	}

	// Required traits - JobConfig is mandatory for Job
	requiredTraits: {
		"opmodel.dev/traits/workload@v0#JobConfig": workload_traits.#JobConfigTrait
	}

	// Optional traits
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#Sizing":            workload_traits.#SizingTrait
		"opmodel.dev/traits/workload@v0#SidecarContainers": workload_traits.#SidecarContainersTrait
		"opmodel.dev/traits/workload@v0#InitContainers":    workload_traits.#InitContainersTrait
		"opmodel.dev/traits/security@v0#SecurityContext":   security_traits.#SecurityContextTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource
		_container: #component.spec.container

		// Extract required JobConfig trait
		_jobConfig: #component.spec.jobConfig

		// Apply defaults for optional RestartPolicy trait
		_restartPolicy: *"OnFailure" | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Build main container with optional trait fields
		_mainContainer: {
			_container

			if #component.spec.sizing != _|_ {
				resources: {
					if #component.spec.sizing.cpu != _|_ || #component.spec.sizing.memory != _|_ {
						requests: {
							if #component.spec.sizing.cpu != _|_ {
								cpu: #component.spec.sizing.cpu.request
							}
							if #component.spec.sizing.memory != _|_ {
								memory: #component.spec.sizing.memory.request
							}
						}
						limits: {
							if #component.spec.sizing.cpu != _|_ {
								cpu: #component.spec.sizing.cpu.limit
							}
							if #component.spec.sizing.memory != _|_ {
								memory: #component.spec.sizing.memory.limit
							}
						}
					}
				}
			}

			if #component.spec.securityContext != _|_ {
				let _sc = #component.spec.securityContext
				if _sc.readOnlyRootFilesystem != _|_ || _sc.allowPrivilegeEscalation != _|_ || _sc.capabilities != _|_ {
					securityContext: {
						if _sc.readOnlyRootFilesystem != _|_ {
							readOnlyRootFilesystem: _sc.readOnlyRootFilesystem
						}
						if _sc.allowPrivilegeEscalation != _|_ {
							allowPrivilegeEscalation: _sc.allowPrivilegeEscalation
						}
						if _sc.capabilities != _|_ {
							capabilities: _sc.capabilities
						}
					}
				}
			}
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
				labels:    #context.labels
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
						containers: list.Concat([[_mainContainer], _sidecarContainers])

						if len(_initContainers) > 0 {
							initContainers: _initContainers
						}

						restartPolicy: _restartPolicy

						if #component.spec.securityContext != _|_ {
							let _sc = #component.spec.securityContext
							if _sc.runAsNonRoot != _|_ || _sc.runAsUser != _|_ || _sc.runAsGroup != _|_ {
								securityContext: {
									if _sc.runAsNonRoot != _|_ {
										runAsNonRoot: _sc.runAsNonRoot
									}
									if _sc.runAsUser != _|_ {
										runAsUser: _sc.runAsUser
									}
									if _sc.runAsGroup != _|_ {
										runAsGroup: _sc.runAsGroup
									}
								}
							}
						}

						if #component.spec.workloadIdentity != _|_ {
							serviceAccountName: #component.spec.workloadIdentity.name
						}
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
