package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/rbac@v1"
)

// #RoleBindingTransformer passes native Kubernetes RoleBinding resources through
// with OPM context applied (name prefix, namespace, labels).
#RoleBindingTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "rolebinding-transformer"
		description: "Passes native Kubernetes RoleBinding resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "rolebinding"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#RoleBindingResource.metadata.fqn): res.#RoleBindingResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_rb:   #component.spec.rolebinding
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _rb.metadata != _|_ {
					if _rb.metadata.annotations != _|_ {
						annotations: _rb.metadata.annotations
					}
				}
			}
			if _rb.subjects != _|_ {
				subjects: _rb.subjects
			}
			if _rb.roleRef != _|_ {
				roleRef: _rb.roleRef
			}
		}
	}
}
