package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/ch_vmm/v1alpha1/resources/workload@v1"
)

// #VMSnapShotTransformer passes native ch-vmm VMSnapShot resources through
// with OPM context applied (name prefix, namespace, labels).
#VMSnapShotTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/ch-vmm/providers/kubernetes/transformers"
		version:     "v1"
		name:        "vm-snap-shot-transformer"
		description: "Passes native ch-vmm VMSnapShot resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "vm-snap-shot"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#VMSnapShotResource.metadata.fqn): res.#VMSnapShotResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vmsn: #component.spec.vmSnapShot
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "cloudhypervisor.quill.today/v1beta1"
			kind:       "VMSnapShot"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _vmsn.metadata != _|_ {
					if _vmsn.metadata.annotations != _|_ {
						annotations: _vmsn.metadata.annotations
					}
				}
			}
			if _vmsn.spec != _|_ {
				spec: _vmsn.spec
			}
		}
	}
}
