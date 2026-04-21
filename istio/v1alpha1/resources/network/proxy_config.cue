package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	pc "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/proxyconfig/v1beta1@v1"
)

/////////////////////////////////////////////////////////////////
//// ProxyConfig Resource Definition (v1beta1)
/////////////////////////////////////////////////////////////////

#ProxyConfigResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "proxy-config"
		description: "An Istio ProxyConfig resource — proxy-side runtime configuration scoped to workloads"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #ProxyConfigDefaults

	spec: close({proxyConfig: {
		metadata?: _#metadata
		spec?:     pc.#ProxyConfigSpec
	}})
}

#ProxyConfig: component.#Component & {
	#resources: {(#ProxyConfigResource.metadata.fqn): #ProxyConfigResource}
}

#ProxyConfigDefaults: {
	metadata?: _#metadata
	spec?:     pc.#ProxyConfigSpec
}
