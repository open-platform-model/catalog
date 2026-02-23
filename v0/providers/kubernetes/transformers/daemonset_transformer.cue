package transformers

import (
	"list"
	k8sappsv1 "opmodel.dev/schemas/kubernetes/apps/v1@v0"
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
	security_traits "opmodel.dev/traits/security@v0"
	storage_resources "opmodel.dev/resources/storage@v0"
)

// DaemonSetTransformer converts daemon workload components to Kubernetes DaemonSets
#DaemonSetTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "daemonset-transformer"
		description: "Converts daemon workload components to Kubernetes DaemonSets"

		labels: {
			"core.opmodel.dev/workload-type": "daemon"
			"core.opmodel.dev/resource-type": "daemonset"
		}
	}

	// Required label to match daemon workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "daemon"
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// Optional resources
	optionalResources: {
		"opmodel.dev/resources/storage@v0#Volumes": storage_resources.#VolumesResource
	}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance daemonset behavior
	// Note: NO Scaling trait - DaemonSets run one pod per node
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#UpdateStrategy":    workload_traits.#UpdateStrategyTrait
		"opmodel.dev/traits/workload@v0#HealthCheck":       workload_traits.#HealthCheckTrait
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

		// Apply defaults for optional traits
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

		// Build container list (main container + optional sidecars)
		_sidecarContainers: *optionalTraits["opmodel.dev/traits/workload@v0#SidecarContainers"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_convertedSidecars: (#ToK8sContainers & {"in": _sidecarContainers}).out
		_containers: list.Concat([
			[_mainContainer],
			_convertedSidecars,
		])

		// Extract init containers with defaults
		_initContainers: *optionalTraits["opmodel.dev/traits/workload@v0#InitContainers"].#defaults | [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		// Build DaemonSet resource
		output: k8sappsv1.#DaemonSet & {
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
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
				selector: matchLabels: #context.componentLabels
				template: {
					metadata: labels: #context.componentLabels
					spec: {
						containers: _containers

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

				if _updateStrategy != null {
					updateStrategy: _updateStrategy
				}
			}
		}
	}
}

_testDaemonSetTransformer: #DaemonSetTransformer.#transform & {
	#component: _testDaemonSetComponent
	#context:   _testContext
}
