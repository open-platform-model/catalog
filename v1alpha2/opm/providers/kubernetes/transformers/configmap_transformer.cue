package transformers

import (
	transformer "opmodel.dev/opm/core/transformer@v1"
	schemas "opmodel.dev/opm/schemas@v1"
	config_resources "opmodel.dev/opm/resources/config@v1"
	k8scorev1 "opmodel.dev/opm/schemas/kubernetes/core/v1@v1"
)

// ConfigMapTransformer converts ConfigMaps resources to Kubernetes ConfigMaps.
// Supports immutable ConfigMaps with content-hash naming.
#ConfigMapTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/providers/kubernetes/transformers"
		version:     "v1"
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
		"opmodel.dev/opm/resources/config/config-maps@v1": config_resources.#ConfigMapsResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_configMaps: #component.spec.configMaps

		// Build the release-scoped prefix: {releaseName}-{componentName}
		// Mirrors the secret-transformer convention so all config resources
		// share the same namespace-isolation guarantee across releases.
		let _relName = #context.#moduleReleaseMetadata.name
		let _compName = #context.#componentMetadata.name

		// Generate a K8s ConfigMap for each entry in the map
		output: {
			for _cmName, cm in _configMaps {
				// Compute the deterministic K8s resource name:
				//   {releaseName}-{componentName}-{cm.name}[-{contenthash}]
				let _baseName = "\(_relName)-\(_compName)-\(cm.name)"
				let _k8sName = (schemas.#ImmutableName & {
					baseName:  _baseName
					data:      cm.data
					immutable: cm.immutable
				}).out

				"\(_k8sName)": k8scorev1.#ConfigMap & {
					apiVersion: "v1"
					kind:       "ConfigMap"
					metadata: {
						name:      _k8sName
						namespace: #context.#moduleReleaseMetadata.namespace
						labels:    #context.labels
						if len(#context.componentAnnotations) > 0 {
							annotations: #context.componentAnnotations
						}
					}
					if cm.immutable == true {
						immutable: true
					}
					data: cm.data
				}
			}
		}
	}
}
