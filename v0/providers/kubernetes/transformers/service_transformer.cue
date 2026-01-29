package transformers

import (
	core "opmodel.dev/core@v0"
	workload_resources "opmodel.dev/resources/workload@v0"
	network_traits "opmodel.dev/traits/network@v0"
)

// ServiceTransformer creates Kubernetes Services from components with Expose trait
#ServiceTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v1"
		name:        "ServiceTransformer"
		description: "Creates Kubernetes Services for components with Expose trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "service"
			"core.opmodel.dev/priority":      "5"
		}
	}

	// Required resources - Container MUST be present to know which ports to expose
	requiredResources: {
		"opmodel.dev/resources/workload@v0#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - Expose is mandatory for Service creation
	requiredTraits: {
		"opmodel.dev/traits/networking@v0#Expose": network_traits.#ExposeTrait
	}

	// No optional traits
	optionalTraits: {}

	#transform: {
		#component: core.#Component
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Extract required Expose trait (will be bottom if not present)
		_expose: #component.spec.expose

		// Build port list from expose trait ports
		_ports: [
			for portName, portConfig in _expose.ports {
				{
					name:       portName
					port:       portConfig.port
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
				labels: {
					app:                      #component.metadata.name
					"app.kubernetes.io/name": #component.metadata.name
					if #component.metadata.labels != _|_ {
						for k, v in #component.metadata.labels {
							"\(k)": v
						}
					}
				}
				if #component.metadata.annotations != _|_ {
					annotations: #component.metadata.annotations
				}
			}
			spec: {
				type: _expose.type

				selector: {
					app: #component.metadata.name
				}

				ports: _ports
			}
		}
	}
}
