package extension

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	wp "opmodel.dev/istio/v1alpha1/schemas/istio/extensions.istio.io/wasmplugin/v1alpha1@v1"
)

/////////////////////////////////////////////////////////////////
//// WasmPlugin Resource Definition (v1alpha1)
/////////////////////////////////////////////////////////////////

#WasmPluginResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/extension"
		version:     "v1"
		name:        "wasm-plugin"
		description: "An Istio WasmPlugin resource — Envoy WASM filter deployment"
		labels: {
			"resource.opmodel.dev/category": "extension"
		}
	}

	#defaults: #WasmPluginDefaults

	spec: close({wasmPlugin: {
		metadata?: _#metadata
		spec?:     wp.#WasmPluginSpec
	}})
}

#WasmPlugin: component.#Component & {
	#resources: {(#WasmPluginResource.metadata.fqn): #WasmPluginResource}
}

#WasmPluginDefaults: {
	metadata?: _#metadata
	spec?:     wp.#WasmPluginSpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
