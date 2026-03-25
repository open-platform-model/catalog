package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/workload@v1"
)

// #JobTransformer passes native Kubernetes Job resources through
// with OPM context applied (name prefix, namespace, labels).
#JobTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "job-transformer"
		description: "Passes native Kubernetes Job resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "job"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#JobResource.metadata.fqn): res.#JobResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_job:  #component.spec.job
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _job.metadata != _|_ {
					if _job.metadata.annotations != _|_ {
						annotations: _job.metadata.annotations
					}
				}
			}
			if _job.spec != _|_ {
				spec: _job.spec
			}
		}
	}
}
