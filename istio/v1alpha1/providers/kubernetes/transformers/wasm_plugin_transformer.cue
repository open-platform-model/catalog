package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/istio/v1alpha1/resources/extension@v1"
)

#WasmPluginTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/istio/providers/kubernetes/transformers"
		version:     "v1"
		name:        "wasm-plugin-transformer"
		description: "Passes native Istio WasmPlugin resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "extension"
			"core.opmodel.dev/resource-type":     "wasm-plugin"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#WasmPluginResource.metadata.fqn): res.#WasmPluginResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_wp:   #component.spec.wasmPlugin
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "extensions.istio.io/v1alpha1"
			kind:       "WasmPlugin"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _wp.metadata != _|_ {
					if _wp.metadata.annotations != _|_ {
						annotations: _wp.metadata.annotations
					}
				}
			}
			if _wp.spec != _|_ {
				spec: _wp.spec
			}
		}
	}
}
