package transformers

import (
	core "opmodel.dev/core@v0"
	config_resources "opmodel.dev/resources/config@v0"
	k8scorev1 "opmodel.dev/schemas/kubernetes/core/v1@v0"
)

// ConfigMapTransformer converts ConfigMaps resources to Kubernetes ConfigMaps
#ConfigMapTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "configmap-transformer"
		description: "Converts ConfigMaps resources to Kubernetes ConfigMaps"

		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "configmap"
		}
	}

	requiredLabels: {}

	// Required resources - ConfigMaps MUST be present
	requiredResources: {
		"opmodel.dev/resources/config@v0#ConfigMaps": config_resources.#ConfigMapsResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_configMaps: #component.spec.configMaps

		// Generate a K8s ConfigMap for each entry in the map
		output: {
			for cmName, cm in _configMaps {
				"\(cmName)": k8scorev1.#ConfigMap & {
					apiVersion: "v1"
					kind:       "ConfigMap"
					metadata: {
						name:      cmName
						namespace: #context.namespace
						labels:    #context.labels
					}
					data: cm.data
				}
			}
		}
	}
}

_testConfigMapTransformer: #ConfigMapTransformer.#transform & {
	#component: _testConfigMapComponent
	#context:   _testContext
}
