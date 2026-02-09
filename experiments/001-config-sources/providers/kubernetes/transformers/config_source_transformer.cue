package transformers

import (
	core "example.com/config-sources/core"
	config_resources "example.com/config-sources/resources/config"
)

// ConfigSourceTransformer emits K8s ConfigMaps and Secrets from ConfigSource resources.
// Inline data sources produce K8s resources; external refs emit nothing.
#ConfigSourceTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "config-source-transformer"
		description: "Emits Kubernetes ConfigMaps and Secrets from ConfigSource resources"

		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "config-source"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/resources/config@v0#ConfigSources": config_resources.#ConfigSourceResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_configSources: #component.spec.configSources

		// Generate a ConfigMap or Secret for each inline source (skip external refs)
		output: {
			for sourceName, source in _configSources if source.data != _|_ {
				"\(sourceName)": {
					if source.type == "config" {
						apiVersion: "v1"
						kind:       "ConfigMap"
						metadata: {
							name:      "\(#component.metadata.name)-\(sourceName)"
							namespace: #context.namespace
							labels:    #context.labels
						}
						data: source.data
					}
					if source.type == "secret" {
						apiVersion: "v1"
						kind:       "Secret"
						metadata: {
							name:      "\(#component.metadata.name)-\(sourceName)"
							namespace: #context.namespace
							labels:    #context.labels
						}
						type: "Opaque"
						data: source.data
					}
				}
			}
		}
	}
}
