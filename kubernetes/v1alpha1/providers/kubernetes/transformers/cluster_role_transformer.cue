package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/rbac@v1"
)

// #ClusterRoleTransformer passes native Kubernetes ClusterRole resources through
// with OPM context applied (name prefix, labels). ClusterRole is cluster-scoped: no namespace.
#ClusterRoleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "clusterrole-transformer"
		description: "Passes native Kubernetes ClusterRole resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "clusterrole"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ClusterRoleResource.metadata.fqn): res.#ClusterRoleResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_cr:   #component.spec.clusterrole
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name:   _name
				labels: #context.labels
				if _cr.metadata != _|_ {
					if _cr.metadata.annotations != _|_ {
						annotations: _cr.metadata.annotations
					}
				}
			}
			if _cr.rules != _|_ {
				rules: _cr.rules
			}
			if _cr.aggregationRule != _|_ {
				aggregationRule: _cr.aggregationRule
			}
		}
	}
}
