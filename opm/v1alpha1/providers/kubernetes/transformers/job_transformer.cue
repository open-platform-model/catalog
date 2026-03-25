package transformers

import (
	"list"
	k8sbatchv1 "opmodel.dev/opm/v1alpha1/schemas/kubernetes/batch/v1@v1"
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
	workload_traits "opmodel.dev/opm/v1alpha1/traits/workload@v1"
	security_traits "opmodel.dev/opm/v1alpha1/traits/security@v1"
	storage_resources "opmodel.dev/opm/v1alpha1/resources/storage@v1"
)

// JobTransformer converts task workload components to Kubernetes Jobs
#JobTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
		version:     "v1"
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
		"opmodel.dev/opm/v1alpha1/resources/workload/container@v1": workload_resources.#ContainerResource
	}

	// Optional resources
	optionalResources: {
		"opmodel.dev/opm/v1alpha1/resources/storage/volumes@v1": storage_resources.#VolumesResource
	}

	// Required traits - JobConfig is mandatory for Job
	requiredTraits: {
		"opmodel.dev/opm/v1alpha1/traits/workload/job-config@v1": workload_traits.#JobConfigTrait
	}

	// Optional traits
	optionalTraits: {
		"opmodel.dev/opm/v1alpha1/traits/workload/restart-policy@v1":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/opm/v1alpha1/traits/workload/sidecar-containers@v1": workload_traits.#SidecarContainersTrait
		"opmodel.dev/opm/v1alpha1/traits/workload/init-containers@v1":    workload_traits.#InitContainersTrait
		"opmodel.dev/opm/v1alpha1/traits/security/security-context@v1":   security_traits.#SecurityContextTrait
		"opmodel.dev/opm/v1alpha1/traits/security/workload-identity@v1":  security_traits.#WorkloadIdentityTrait
		"opmodel.dev/opm/v1alpha1/traits/security/host-pid@v1":           security_traits.#HostPIDTrait
		"opmodel.dev/opm/v1alpha1/traits/security/host-ipc@v1":           security_traits.#HostIPCTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   transformer.#TransformerContext

		// Extract required Container resource
		_container: #component.spec.container

		// Extract required JobConfig trait
		_jobConfig: #component.spec.jobConfig

		// Apply defaults for optional RestartPolicy trait
		_restartPolicy: *"OnFailure" | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Build main container: base conversion via helper, unified with trait fields
		_mainContainer: (#ToK8sContainer & {"in": _container, #releasePrefix: #context.#moduleReleaseMetadata.name}).out

		// Extract optional sidecar and init containers with defaults
		_sidecarContainers: *optionalTraits["opmodel.dev/opm/v1alpha1/traits/workload/sidecar-containers@v1"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_initContainers: *optionalTraits["opmodel.dev/opm/v1alpha1/traits/workload/init-containers@v1"].#defaults | [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		output: k8sbatchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				// Include component annotations if present
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				completions: *requiredTraits["opmodel.dev/opm/v1alpha1/traits/workload/job-config@v1"].#defaults.completions | int
				if _jobConfig.completions != _|_ {
					completions: _jobConfig.completions
				}

				parallelism: *requiredTraits["opmodel.dev/opm/v1alpha1/traits/workload/job-config@v1"].#defaults.parallelism | int
				if _jobConfig.parallelism != _|_ {
					parallelism: _jobConfig.parallelism
				}

				backoffLimit: *requiredTraits["opmodel.dev/opm/v1alpha1/traits/workload/job-config@v1"].#defaults.backoffLimit | int
				if _jobConfig.backoffLimit != _|_ {
					backoffLimit: _jobConfig.backoffLimit
				}

				activeDeadlineSeconds: *requiredTraits["opmodel.dev/opm/v1alpha1/traits/workload/job-config@v1"].#defaults.activeDeadlineSeconds | int
				if _jobConfig.activeDeadlineSeconds != _|_ {
					activeDeadlineSeconds: _jobConfig.activeDeadlineSeconds
				}

				ttlSecondsAfterFinished: *requiredTraits["opmodel.dev/opm/v1alpha1/traits/workload/job-config@v1"].#defaults.ttlSecondsAfterFinished | int
				if _jobConfig.ttlSecondsAfterFinished != _|_ {
					ttlSecondsAfterFinished: _jobConfig.ttlSecondsAfterFinished
				}

				template: {
					metadata: labels: #context.componentLabels
					spec: {
						_convertedSidecars: (#ToK8sContainers & {"in": _sidecarContainers, #releasePrefix: #context.#moduleReleaseMetadata.name}).out
						containers: list.Concat([[_mainContainer], _convertedSidecars])

						if len(_initContainers) > 0 {
							initContainers: (#ToK8sContainers & {"in": _initContainers, #releasePrefix: #context.#moduleReleaseMetadata.name}).out
						}

						restartPolicy: _restartPolicy

						if #component.spec.hostPid != _|_ {
							hostPID: #component.spec.hostPid
						}

						if #component.spec.hostIpc != _|_ {
							hostIPC: #component.spec.hostIpc
						}

						if #component.spec.securityContext != _|_ {
							let _sc = #component.spec.securityContext
							if _sc.runAsNonRoot != _|_ || _sc.runAsUser != _|_ || _sc.runAsGroup != _|_ || _sc.supplementalGroups != _|_ {
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
									if _sc.supplementalGroups != _|_ {
										supplementalGroups: _sc.supplementalGroups
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
