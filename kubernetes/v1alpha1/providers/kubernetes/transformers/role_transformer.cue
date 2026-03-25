package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/rbac@v1"
)

// #RoleTransformer passes native Kubernetes Role resources through
// with OPM context applied (name prefix, namespace, labels).
#RoleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "role-transformer"
		description: "Passes native Kubernetes Role resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "role"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#RoleResource.metadata.fqn): res.#RoleResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_role: #component.spec.role
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _role.metadata != _|_ {
					if _role.metadata.annotations != _|_ {
						annotations: _role.metadata.annotations
					}
				}
			}
			if _role.rules != _|_ {
				rules: _role.rules
			}
		}
	}
}
