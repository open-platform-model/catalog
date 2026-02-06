package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	workload_traits "opmodel.dev/traits/workload@v0"
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

	// No optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance deployment behavior
	optionalTraits: {
		"opmodel.dev/traits/workload@v0#Replicas":          workload_traits.#ReplicasTrait
		"opmodel.dev/traits/workload@v0#RestartPolicy":     workload_traits.#RestartPolicyTrait
		"opmodel.dev/traits/workload@v0#UpdateStrategy":    workload_traits.#UpdateStrategyTrait
		"opmodel.dev/traits/workload@v0#HealthCheck":       workload_traits.#HealthCheckTrait
		"opmodel.dev/traits/workload@v0#SidecarContainers": workload_traits.#SidecarContainersTrait
		"opmodel.dev/traits/workload@v0#InitContainers":    workload_traits.#InitContainersTrait
	}

	// Transform function
	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource
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
				replicas: _replicas
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
