package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	dr "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/destinationrule/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// DestinationRule Resource Definition
/////////////////////////////////////////////////////////////////

#DestinationRuleResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "destination-rule"
		description: "An Istio DestinationRule resource for policies applied to traffic intended for a service"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #DestinationRuleDefaults

	spec: close({destinationRule: {
		metadata?: _#metadata
		spec?:     dr.#DestinationRuleSpec
	}})
}

#DestinationRule: component.#Component & {
	#resources: {(#DestinationRuleResource.metadata.fqn): #DestinationRuleResource}
}

#DestinationRuleDefaults: {
	metadata?: _#metadata
	spec?:     dr.#DestinationRuleSpec
}
