package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/cluster@v1"
)

// #NamespaceTransformer passes native Kubernetes Namespace resources through
// with OPM context applied (name prefix, labels). Namespace is cluster-scoped: no namespace in metadata.
#NamespaceTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "namespace-transformer"
		description: "Passes native Kubernetes Namespace resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "namespace"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#NamespaceResource.metadata.fqn): res.#NamespaceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_nsSpec: #component.spec.namespace
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Namespace"
			metadata: {
				name:   _name
				labels: #context.labels
				if _nsSpec.metadata != _|_ {
					if _nsSpec.metadata.annotations != _|_ {
						annotations: _nsSpec.metadata.annotations
					}
				}
			}
			if _nsSpec.spec != _|_ {
				spec: _nsSpec.spec
			}
		}
	}
}
