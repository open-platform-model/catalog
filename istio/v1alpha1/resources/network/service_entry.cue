package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	se "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/serviceentry/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// ServiceEntry Resource Definition
/////////////////////////////////////////////////////////////////

#ServiceEntryResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "service-entry"
		description: "An Istio ServiceEntry resource for adding external services to the mesh registry"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #ServiceEntryDefaults

	spec: close({serviceEntry: {
		metadata?: _#metadata
		spec?:     se.#ServiceEntrySpec
	}})
}

#ServiceEntry: component.#Component & {
	#resources: {(#ServiceEntryResource.metadata.fqn): #ServiceEntryResource}
}

#ServiceEntryDefaults: {
	metadata?: _#metadata
	spec?:     se.#ServiceEntrySpec
}
