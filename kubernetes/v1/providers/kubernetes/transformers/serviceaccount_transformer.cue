package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/rbac@v1"
)

// #ServiceAccountTransformer passes native Kubernetes ServiceAccount resources through
// with OPM context applied (name prefix, namespace, labels).
#ServiceAccountTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "serviceaccount-transformer"
		description: "Passes native Kubernetes ServiceAccount resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "serviceaccount"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ServiceAccountResource.metadata.fqn): res.#ServiceAccountResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_sa:   #component.spec.serviceaccount
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _sa.metadata != _|_ {
					if _sa.metadata.annotations != _|_ {
						annotations: _sa.metadata.annotations
					}
				}
			}
			if _sa.automountServiceAccountToken != _|_ {
				automountServiceAccountToken: _sa.automountServiceAccountToken
			}
			if _sa.imagePullSecrets != _|_ {
				imagePullSecrets: _sa.imagePullSecrets
			}
			if _sa.secrets != _|_ {
				secrets: _sa.secrets
			}
		}
	}
}
