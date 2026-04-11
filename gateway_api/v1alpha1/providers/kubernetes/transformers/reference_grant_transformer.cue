package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/gateway_api/v1alpha1/resources/network@v1"
)

// #ReferenceGrantTransformer passes native Gateway API ReferenceGrant resources through
// with OPM context applied (name prefix, namespace, labels).
#ReferenceGrantTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/gateway-api/providers/kubernetes/transformers"
		version:     "v1"
		name:        "reference-grant-transformer"
		description: "Passes native Gateway API ReferenceGrant resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "reference-grant"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ReferenceGrantResource.metadata.fqn): res.#ReferenceGrantResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_refGrant: #component.spec.referenceGrant
		_name:     "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "gateway.networking.k8s.io/v1"
			kind:       "ReferenceGrant"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _refGrant.metadata != _|_ {
					if _refGrant.metadata.annotations != _|_ {
						annotations: _refGrant.metadata.annotations
					}
				}
			}
			if _refGrant.spec != _|_ {
				spec: _refGrant.spec
			}
		}
	}
}
