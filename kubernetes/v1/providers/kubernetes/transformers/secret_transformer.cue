package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/config@v1"
)

// #SecretTransformer passes native Kubernetes Secret resources through
// with OPM context applied (name prefix, namespace, labels).
#SecretTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "secret-transformer"
		description: "Passes native Kubernetes Secret resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "secret"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#SecretResource.metadata.fqn): res.#SecretResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_secret: #component.spec.secret
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _secret.metadata != _|_ {
					if _secret.metadata.annotations != _|_ {
						annotations: _secret.metadata.annotations
					}
				}
			}
			if _secret.type != _|_ {
				type: _secret.type
			}
			if _secret.data != _|_ {
				data: _secret.data
			}
			if _secret.stringData != _|_ {
				stringData: _secret.stringData
			}
			if _secret.immutable != _|_ {
				immutable: _secret.immutable
			}
		}
	}
}
