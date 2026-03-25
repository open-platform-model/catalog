package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1/resources/workload@v1"
)

// #DaemonSetTransformer passes native Kubernetes DaemonSet resources through
// with OPM context applied (name prefix, namespace, labels).
#DaemonSetTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "daemonset-transformer"
		description: "Passes native Kubernetes DaemonSet resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "daemonset"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#DaemonSetResource.metadata.fqn): res.#DaemonSetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_ds:   #component.spec.daemonset
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _ds.metadata != _|_ {
					if _ds.metadata.annotations != _|_ {
						annotations: _ds.metadata.annotations
					}
				}
			}
			if _ds.spec != _|_ {
				spec: _ds.spec
			}
		}
	}
}
