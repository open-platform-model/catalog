package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	security_traits "opmodel.dev/traits/security@v0"
	security_resources "opmodel.dev/resources/security@v0"
	"list"
)

// DeploymentTransformer converts stateless workload components to Kubernetes Deployments
#DeploymentTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "deployment-transformer"
		description: "Converts stateless workload components with Container resource to Kubernetes Deployments"

		labels: {
			"core.opmodel.dev/workload-type": "stateless"
			"core.opmodel.dev/resource-type": "deployment"
		}
	}

	// Required label to match stateless workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "stateless"
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// Optional resources
	optionalResources: {
		"opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource
	}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance deployment behavior
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#Scaling":           workload_traits.#ScalingTrait
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#UpdateStrategy":    workload_traits.#UpdateStrategyTrait
		"opmodel.dev/traits/workload@v0#HealthCheck":       workload_traits.#HealthCheckTrait
		"opmodel.dev/traits/workload@v0#Sizing":            workload_traits.#SizingTrait
		"opmodel.dev/traits/workload@v0#SidecarContainers": workload_traits.#SidecarContainersTrait
		"opmodel.dev/traits/workload@v0#InitContainers":    workload_traits.#InitContainersTrait
		"opmodel.dev/traits/security@v0#SecurityContext":   security_traits.#SecurityContextTrait
	}

	// Transform function
	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource
		_container: #component.spec.container

		// Apply defaults for optional traits
		_scalingCount: *optionalTraits["opmodel.dev/traits/workload@v0#Scaling"].#defaults.count | int
		if #component.spec.scaling != _|_ if #component.spec.scaling.auto != _|_ {
			_scalingCount: #component.spec.scaling.auto.min
		}
		if #component.spec.scaling != _|_ if #component.spec.scaling.auto == _|_ {
			_scalingCount: #component.spec.scaling.count
		}

		_restartPolicy: *optionalTraits["opmodel.dev/traits/workload@v0#RestartPolicy"].#defaults | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Extract update strategy with defaults
		_updateStrategy: *null | {
			if #component.spec.updateStrategy != _|_ {
				type: #component.spec.updateStrategy.type
				if #component.spec.updateStrategy.type == "RollingUpdate" {
					rollingUpdate: #component.spec.updateStrategy.rollingUpdate
				}
			}
		}

		// Build main container with optional trait fields
		_mainContainer: {
			_container

			// HealthCheck: emit probes on main container
			if #component.spec.healthCheck != _|_ {
				if #component.spec.healthCheck.livenessProbe != _|_ {
					livenessProbe: #component.spec.healthCheck.livenessProbe
				}
				if #component.spec.healthCheck.readinessProbe != _|_ {
					readinessProbe: #component.spec.healthCheck.readinessProbe
				}
			}

			// Sizing: emit resources on main container
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

			// SecurityContext: container-level fields
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

		// Build container list (main container + optional sidecars)
		_sidecarContainers: *optionalTraits["opmodel.dev/traits/workload@v0#SidecarContainers"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_containers: list.Concat([
			[_mainContainer],
			_sidecarContainers,
		])

		// Extract init containers with defaults
		_initContainers: *optionalTraits["opmodel.dev/traits/workload@v0#InitContainers"].#defaults | [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		// Build Deployment resource
		output: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace
				labels:    #context.labels
				if #context.componentAnnotations != _|_ {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				replicas: _scalingCount
				selector: matchLabels: #context.componentLabels
				template: {
					metadata: labels: #context.componentLabels
					spec: {
						containers: _containers

						if len(_initContainers) > 0 {
							initContainers: _initContainers
						}

						restartPolicy: _restartPolicy

						// SecurityContext: pod-level fields
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

						// ServiceAccount reference
						if #component.spec.workloadIdentity != _|_ {
							serviceAccountName: #component.spec.workloadIdentity.name
						}
					}
				}

				if _updateStrategy != null {
					strategy: _updateStrategy
				}
			}
		}
	}
}

_testDeploymentTransformer: #DeploymentTransformer.#transform & {
	#component: _testComponent
	#context:   _testContext
}
