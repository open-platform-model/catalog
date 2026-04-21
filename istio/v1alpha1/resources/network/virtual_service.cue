package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	vs "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/virtualservice/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// VirtualService Resource Definition
/////////////////////////////////////////////////////////////////

#VirtualServiceResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "virtual-service"
		description: "An Istio VirtualService resource for L7 traffic routing"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #VirtualServiceDefaults

	spec: close({virtualService: {
		metadata?: _#metadata
		spec?:     vs.#VirtualServiceSpec
	}})
}

#VirtualService: component.#Component & {
	#resources: {(#VirtualServiceResource.metadata.fqn): #VirtualServiceResource}
}

#VirtualServiceDefaults: {
	metadata?: _#metadata
	spec?:     vs.#VirtualServiceSpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
