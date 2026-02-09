package transformers

import (
	core "example.com/config-sources/core"
	workload_resources "example.com/config-sources/resources/workload"
	workload_traits "example.com/config-sources/traits/workload"
	security_traits "example.com/config-sources/traits/security"
	"list"
)

// StatefulsetTransformer converts stateful workload components to Kubernetes StatefulSets
#StatefulsetTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "statefulset-transformer"
		description: "Converts stateful workload components to Kubernetes StatefulSets"

		labels: {
			"core.opmodel.dev/workload-type": "stateful"
			"core.opmodel.dev/resource-type": "statefulset"
		}
	}

	// Required label to match stateful workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "stateful"
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// Optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance statefulset behavior
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#Scaling":           workload_traits.#ScalingTrait
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#UpdateStrategy":    workload_traits.#UpdateStrategyTrait
		"opmodel.dev/traits/workload@v0#HealthCheck":       workload_traits.#HealthCheckTrait
		"opmodel.dev/traits/workload@v0#Sizing":            workload_traits.#SizingTrait
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

		// Resolve config source names to K8s resource names
		_configSources: *null | {...}
		if #component.spec.configSources != _|_ {
			_configSources: #component.spec.configSources
		}

		// Build main container with optional trait fields
		_mainContainer: {
			_container

			// ConfigSources: resolve env.from references to K8s valueFrom
			if _configSources != null if _container.env != _|_ {
				env: {
					for envName, envVar in _container.env {
						if envVar.from != _|_ {
							let _src = _configSources[envVar.from.source]
							let _resolvedName = "\(#component.metadata.name)-\(envVar.from.source)"
							if _src.externalRef != _|_ {
								(envName): {
									name: envVar.name
									if _src.type == "secret" {
										valueFrom: secretKeyRef: {
											name: _src.externalRef.name
											key:  envVar.from.key
										}
									}
									if _src.type == "config" {
										valueFrom: configMapKeyRef: {
											name: _src.externalRef.name
											key:  envVar.from.key
										}
									}
								}
							}
							if _src.externalRef == _|_ {
								(envName): {
									name: envVar.name
									if _src.type == "secret" {
										valueFrom: secretKeyRef: {
											name: _resolvedName
											key:  envVar.from.key
										}
									}
									if _src.type == "config" {
										valueFrom: configMapKeyRef: {
											name: _resolvedName
											key:  envVar.from.key
										}
									}
								}
							}
						}
					}
				}
			}

			if #component.spec.healthCheck != _|_ {
				if #component.spec.healthCheck.livenessProbe != _|_ {
					livenessProbe: #component.spec.healthCheck.livenessProbe
				}
				if #component.spec.healthCheck.readinessProbe != _|_ {
					readinessProbe: #component.spec.healthCheck.readinessProbe
				}
			}

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

		// Build StatefulSet resource
		output: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace | *"default"
				labels:    #context.labels
				if #component.metadata.annotations != _|_ {
					annotations: #component.metadata.annotations
				}
			}
			spec: {
				serviceName: #component.metadata.name
				replicas:    _scalingCount
				selector: matchLabels: #context.componentLabels
				template: {
					metadata: labels: #context.componentLabels
					spec: {
						containers: _containers

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

				if _updateStrategy != null {
					updateStrategy: _updateStrategy
				}
			}
		}
	}
}

_testStatefulsetTransformer: #StatefulsetTransformer.#transform & {
	#component: _testStatefulSetComponent
	#context:   _testContext
}
