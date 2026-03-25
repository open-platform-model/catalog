package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/workload@v1"
)

// #CronJobTransformer passes native Kubernetes CronJob resources through
// with OPM context applied (name prefix, namespace, labels).
#CronJobTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "cronjob-transformer"
		description: "Passes native Kubernetes CronJob resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "cronjob"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#CronJobResource.metadata.fqn): res.#CronJobResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_cj:   #component.spec.cronjob
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "batch/v1"
			kind:       "CronJob"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _cj.metadata != _|_ {
					if _cj.metadata.annotations != _|_ {
						annotations: _cj.metadata.annotations
					}
				}
			}
			if _cj.spec != _|_ {
				spec: _cj.spec
			}
		}
	}
}
