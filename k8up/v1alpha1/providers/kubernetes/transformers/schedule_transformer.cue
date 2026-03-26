package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/k8up/v1alpha1/resources/backup@v1"
)

// #ScheduleTransformer passes K8up Schedule resources through
// with OPM context applied (name prefix, namespace, labels).
#ScheduleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/providers/kubernetes/transformers"
		version:     "v1"
		name:        "schedule-transformer"
		description: "Passes K8up Schedule resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "schedule"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ScheduleResource.metadata.fqn): res.#ScheduleResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_schedule: #component.spec.schedule
		_name:     "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "Schedule"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _schedule.metadata != _|_ {
					if _schedule.metadata.annotations != _|_ {
						annotations: _schedule.metadata.annotations
					}
				}
			}
			if _schedule.spec != _|_ {
				spec: _schedule.spec
			}
		}
	}
}
