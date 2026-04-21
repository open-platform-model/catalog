package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	sc "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/sidecar/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// Sidecar Resource Definition
/////////////////////////////////////////////////////////////////

#SidecarResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "sidecar"
		description: "An Istio Sidecar resource for configuring the Envoy proxy associated with a workload"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #SidecarDefaults

	spec: close({sidecar: {
		metadata?: _#metadata
		spec?:     sc.#SidecarSpec
	}})
}

#Sidecar: component.#Component & {
	#resources: {(#SidecarResource.metadata.fqn): #SidecarResource}
}

#SidecarDefaults: {
	metadata?: _#metadata
	spec?:     sc.#SidecarSpec
}
