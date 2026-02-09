package transformers

import (
	core "opmodel.dev/core@v0"
	config_resources "opmodel.dev/resources/config@v0"
)

// ConfigMapTransformer converts ConfigMap resources to Kubernetes ConfigMaps
#ConfigMapTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "configmap-transformer"
		description: "Converts ConfigMap resources to Kubernetes ConfigMaps"

		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "configmap"
		}
	}

	requiredLabels: {}

	// Required resources - ConfigMap MUST be present
	requiredResources: {
		"opmodel.dev/resources/config@v0#ConfigMap": config_resources.#ConfigMapResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_configMap: #component.spec.configMap

		output: {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace
				labels:    #context.labels
			}
			data: _configMap.data
		}
	}
}

_testConfigMapTransformer: #ConfigMapTransformer.#transform & {
	#component: _testConfigMapComponent
	#context:   _testContext
}
