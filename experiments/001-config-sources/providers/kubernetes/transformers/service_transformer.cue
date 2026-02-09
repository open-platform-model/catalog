package transformers

import (
	core "example.com/config-sources/core"
	workload_resources "example.com/config-sources/resources/workload"
	network_traits "example.com/config-sources/traits/network"
)

// ServiceTransformer creates Kubernetes Services from components with Expose trait
#ServiceTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "service-transformer"
		description: "Creates Kubernetes Services for components with Expose trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "service"
		}
	}

	requiredLabels: {} // No specific labels required; matches any component with Expose trait

	// Required resources - Container MUST be present to know which ports to expose
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - Expose is mandatory for Service creation
	requiredTraits: {
		"opmodel.dev/traits/network@v0#Expose": network_traits.#ExposeTrait
	}

	// No optional traits
	optionalTraits: {}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Extract required Expose trait (will be bottom if not present)
		_expose: #component.spec.expose

		// Build port list from expose trait ports
		// Schema: targetPort = container port, exposedPort = optional external port
		// K8s Service: port = service port (external), targetPort = pod port
		_ports: [
			for portName, portConfig in _expose.ports {
				{
					name: portName
					// Service port: use exposedPort if specified, else targetPort
					port:       portConfig.exposedPort | *portConfig.targetPort
					targetPort: portConfig.targetPort
					protocol:   portConfig.protocol | *"TCP"
					if _expose.type == "NodePort" && portConfig.exposedPort != _|_ {
						nodePort: portConfig.exposedPort
					}
				}
			},
		]

		// Build Service resource
		output: {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace | *"default"
				labels:    #context.labels
				if #component.metadata.annotations != _|_ {
					annotations: #component.metadata.annotations
				}
			}
			spec: {
				type: _expose.type

				selector: #context.componentLabels

				ports: _ports
			}
		}
	}
}

_testServiceTransformer: #ServiceTransformer.#transform & {
	#component: _testServiceComponent
	#context:   _testContext
}
