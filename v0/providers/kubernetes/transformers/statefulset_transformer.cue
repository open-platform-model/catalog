package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
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

	// No optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance statefulset behavior
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#Replicas":          workload_traits.#ReplicasTrait
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#UpdateStrategy":    workload_traits.#UpdateStrategyTrait
		"opmodel.dev/traits/workload@v0#HealthCheck":       workload_traits.#HealthCheckTrait
		"opmodel.dev/traits/workload@v0#SidecarContainers": workload_traits.#SidecarContainersTrait
		"opmodel.dev/traits/workload@v0#InitContainers":    workload_traits.#InitContainersTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Apply defaults for optional traits
		_replicas: *optionalTraits["opmodel.dev/traits/workload@v0#Replicas"].#defaults | int
		if #component.spec.replicas != _|_ {
			_replicas: #component.spec.replicas
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

		// Build container list (main container + optional sidecars)
		_sidecarContainers: *optionalTraits["opmodel.dev/traits/workload@v0#SidecarContainers"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_containers: list.Concat([
			[_container],
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
				replicas:    _replicas
				selector: matchLabels: #context.componentLabels
				template: {
					metadata: labels: #context.componentLabels
					spec: {
						containers: _containers

						if len(_initContainers) > 0 {
							initContainers: _initContainers
						}

						restartPolicy: _restartPolicy
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
