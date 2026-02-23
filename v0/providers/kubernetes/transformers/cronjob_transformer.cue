package transformers

import (
	"list"
	k8sbatchv1 "opmodel.dev/schemas/kubernetes/batch/v1@v0"
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	security_traits "opmodel.dev/traits/security@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
)

// CronJobTransformer converts scheduled task components to Kubernetes CronJobs
#CronJobTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "cronjob-transformer"
		description: "Converts scheduled task components to Kubernetes CronJobs"

		labels: {
			"core.opmodel.dev/workload-type": "scheduled-task"
			"core.opmodel.dev/resource-type": "cronjob"
		}
	}

	// Required label to match scheduled task workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "scheduled-task"
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// Optional resources
	optionalResources: {
		"opmodel.dev/resources/storage@v0#Volumes": storage_resources.#VolumesResource
	}

	// Required traits - CronJobConfig is mandatory for CronJob
	requiredTraits: {
		"opmodel.dev/traits/workload@v0#CronJobConfig": workload_traits.#CronJobConfigTrait
	}

	// Optional traits
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#SidecarContainers": workload_traits.#SidecarContainersTrait
		"opmodel.dev/traits/workload@v0#InitContainers":    workload_traits.#InitContainersTrait
		"opmodel.dev/traits/security@v0#SecurityContext":   security_traits.#SecurityContextTrait
		"opmodel.dev/traits/security@v0#WorkloadIdentity":  security_traits.#WorkloadIdentityTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource
		_container: #component.spec.container

		// Extract required CronJobConfig trait
		_cronConfig: #component.spec.cronJobConfig

		// Apply defaults for optional RestartPolicy trait
		_restartPolicy: *"OnFailure" | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Build main container: base conversion via helper, unified with trait fields
		_mainContainer: (#ToK8sContainer & {"in": _container}).out & {
			if #component.spec.healthCheck != _|_ {
				if #component.spec.healthCheck.startupProbe != _|_ {
					startupProbe: #component.spec.healthCheck.startupProbe
				}
				if #component.spec.healthCheck.livenessProbe != _|_ {
					livenessProbe: #component.spec.healthCheck.livenessProbe
				}
				if #component.spec.healthCheck.readinessProbe != _|_ {
					readinessProbe: #component.spec.healthCheck.readinessProbe
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

		output: k8sbatchv1.#CronJob & {
			apiVersion: "batch/v1"
			kind:       "CronJob"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace | *"default"
				labels:    #context.labels
				// Include component annotations if present
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				schedule: _cronConfig.scheduleCron

				if _cronConfig.suspend != _|_ {
					suspend: _cronConfig.suspend
				}

				concurrencyPolicy: *requiredTraits["opmodel.dev/traits/workload@v0#CronJobConfig"].#defaults.concurrencyPolicy | string
				if _cronConfig.concurrencyPolicy != _|_ {
					concurrencyPolicy: _cronConfig.concurrencyPolicy
				}

				successfulJobsHistoryLimit: *requiredTraits["opmodel.dev/traits/workload@v0#CronJobConfig"].#defaults.successfulJobsHistoryLimit | int
				if _cronConfig.successfulJobsHistoryLimit != _|_ {
					successfulJobsHistoryLimit: _cronConfig.successfulJobsHistoryLimit
				}

				failedJobsHistoryLimit: *requiredTraits["opmodel.dev/traits/workload@v0#CronJobConfig"].#defaults.failedJobsHistoryLimit | int
				if _cronConfig.failedJobsHistoryLimit != _|_ {
					failedJobsHistoryLimit: _cronConfig.failedJobsHistoryLimit
				}

				jobTemplate: {
					spec: {
						template: {
							metadata: labels: #context.componentLabels
							spec: {
								_convertedSidecars: (#ToK8sContainers & {"in": _sidecarContainers}).out
								containers: list.Concat([[_mainContainer], _convertedSidecars])

								if len(_initContainers) > 0 {
									initContainers: (#ToK8sContainers & {"in": _initContainers}).out
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

								// Volumes: map persistent claim volumes to PVC references
								if #component.spec.volumes != _|_ {
									volumes: [
										for vName, vol in #component.spec.volumes if vol.persistentClaim != _|_ {
											name: vol.name | *vName
											persistentVolumeClaim: claimName: vol.name | *vName
										},
									]
								}
							}
						}
					}
				}
			}
		}
	}
}

_testCronJobTransformer: #CronJobTransformer.#transform & {
	#component: _testCronJobComponent
	#context:   _testContext
}
