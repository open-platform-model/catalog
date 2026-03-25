package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/workload@v1"
)

// #DeploymentTransformer passes native Kubernetes Deployment resources through
// with OPM context applied (name prefix, namespace, labels).
#DeploymentTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "deployment-transformer"
		description: "Passes native Kubernetes Deployment resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "deployment"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#DeploymentResource.metadata.fqn): res.#DeploymentResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_deploy: #component.spec.deployment
		_name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _deploy.metadata != _|_ {
					if _deploy.metadata.annotations != _|_ {
						annotations: _deploy.metadata.annotations
					}
				}
			}
			if _deploy.spec != _|_ {
				spec: _deploy.spec
			}
		}
	}
}
