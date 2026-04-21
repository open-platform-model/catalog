package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	ef "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/envoyfilter/v1alpha3@v1"
)

/////////////////////////////////////////////////////////////////
//// EnvoyFilter Resource Definition (v1alpha3)
/////////////////////////////////////////////////////////////////

#EnvoyFilterResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "envoy-filter"
		description: "An Istio EnvoyFilter resource — direct Envoy configuration patches (advanced, use sparingly)"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #EnvoyFilterDefaults

	spec: close({envoyFilter: {
		metadata?: _#metadata
		spec?:     ef.#EnvoyFilterSpec
	}})
}

#EnvoyFilter: component.#Component & {
	#resources: {(#EnvoyFilterResource.metadata.fqn): #EnvoyFilterResource}
}

#EnvoyFilterDefaults: {
	metadata?: _#metadata
	spec?:     ef.#EnvoyFilterSpec
}
