package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/rbac@v1"
)

// #ClusterRoleBindingTransformer passes native Kubernetes ClusterRoleBinding resources through
// with OPM context applied (name prefix, labels). ClusterRoleBinding is cluster-scoped: no namespace.
#ClusterRoleBindingTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "clusterrolebinding-transformer"
		description: "Passes native Kubernetes ClusterRoleBinding resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "clusterrolebinding"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ClusterRoleBindingResource.metadata.fqn): res.#ClusterRoleBindingResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_crb:  #component.spec.clusterrolebinding
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name:   _name
				labels: #context.labels
				if _crb.metadata != _|_ {
					if _crb.metadata.annotations != _|_ {
						annotations: _crb.metadata.annotations
					}
				}
			}
			if _crb.subjects != _|_ {
				subjects: _crb.subjects
			}
			if _crb.roleRef != _|_ {
				roleRef: _crb.roleRef
			}
		}
	}
}
