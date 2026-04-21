package network

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	gw "opmodel.dev/istio/v1alpha1/schemas/istio/networking.istio.io/gateway/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// Istio Gateway Resource Definition
//// (distinct from Gateway API Gateway — this is networking.istio.io/v1)
/////////////////////////////////////////////////////////////////

#IstioGatewayResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/istio/resources/network"
		version:     "v1"
		name:        "istio-gateway"
		description: "An Istio Gateway resource (networking.istio.io/v1) — sidecar-mode ingress/egress configuration"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	#defaults: #IstioGatewayDefaults

	spec: close({istioGateway: {
		metadata?: _#metadata
		spec?:     gw.#GatewaySpec
	}})
}

#IstioGateway: component.#Component & {
	#resources: {(#IstioGatewayResource.metadata.fqn): #IstioGatewayResource}
}

#IstioGatewayDefaults: {
	metadata?: _#metadata
	spec?:     gw.#GatewaySpec
}
