package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/network@v1"
)

// #NetworkPolicyTransformer passes native Kubernetes NetworkPolicy resources through
// with OPM context applied (name prefix, namespace, labels).
#NetworkPolicyTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "networkpolicy-transformer"
		description: "Passes native Kubernetes NetworkPolicy resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "networkpolicy"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#NetworkPolicyResource.metadata.fqn): res.#NetworkPolicyResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_np:   #component.spec.networkpolicy
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _np.metadata != _|_ {
					if _np.metadata.annotations != _|_ {
						annotations: _np.metadata.annotations
					}
				}
			}
			if _np.spec != _|_ {
				spec: _np.spec
			}
		}
	}
}
