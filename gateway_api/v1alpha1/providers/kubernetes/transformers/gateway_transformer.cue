package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	gwV1 "gateway.networking.k8s.io/gateway/v1"
)

// GatewayTransformer creates Gateway API Gateways from GatewayResource components.
// When an issuerRef is present in the schema, cert-manager annotations are added
// to request automated TLS certificate management.
#GatewayTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "gateway-transformer"
		description: "Creates Gateway API Gateways with optional cert-manager annotation support"

		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "gateway"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/gateway@v1": _
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_gateway: #component.spec.gateway
		_name:    "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		// Merge component annotations with cert-manager issuer annotation if specified
		_gatewayAnnotations: #context.componentAnnotations & {
			if _gateway.issuerRef != _|_ {
				if _gateway.issuerRef.kind == "ClusterIssuer" {
					"cert-manager.io/cluster-issuer": _gateway.issuerRef.name
				}
				if _gateway.issuerRef.kind == "Issuer" {
					"cert-manager.io/issuer": _gateway.issuerRef.name
				}
			}
		}

		output: gwV1.#Gateway & {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "Gateway"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(_gatewayAnnotations) > 0 {
					annotations: _gatewayAnnotations
				}
			}
			spec: {
				gatewayClassName: _gateway.gatewayClassName
				listeners:        _gateway.listeners
				if _gateway.addresses != _|_ {
					addresses: _gateway.addresses
				}
			}
		}
	}
}
