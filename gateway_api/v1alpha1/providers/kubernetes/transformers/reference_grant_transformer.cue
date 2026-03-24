package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	refgV1 "gateway.networking.k8s.io/referencegrant/v1"
)

// ReferenceGrantTransformer creates Gateway API ReferenceGrants from ReferenceGrantResource components.
// ReferenceGrants permit cross-namespace access between Gateway API resources.
#ReferenceGrantTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "reference-grant-transformer"
		description: "Creates Gateway API ReferenceGrants to permit cross-namespace resource access"

		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "reference-grant"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/gateway-api/resources/network/reference-grant@v1": _
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_referenceGrant: #component.spec.referenceGrant
		_name:           "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: refgV1.#ReferenceGrant & {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "ReferenceGrant"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				from: _referenceGrant.from
				to:   _referenceGrant.to
			}
		}
	}
}
