package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/admission@v1"
)

// #MutatingWebhookConfigurationTransformer passes native Kubernetes
// MutatingWebhookConfiguration resources through with OPM context applied.
// MutatingWebhookConfiguration is cluster-scoped: no namespace.
#MutatingWebhookConfigurationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "mutatingwebhookconfiguration-transformer"
		description: "Passes native Kubernetes MutatingWebhookConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "mutatingwebhookconfiguration"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#MutatingWebhookConfigurationResource.metadata.fqn): res.#MutatingWebhookConfigurationResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_mwc:  #component.spec.mutatingwebhookconfiguration
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "admissionregistration.k8s.io/v1"
			kind:       "MutatingWebhookConfiguration"
			metadata: {
				name:   _name
				labels: #context.labels
				if _mwc.metadata != _|_ {
					if _mwc.metadata.annotations != _|_ {
						annotations: _mwc.metadata.annotations
					}
				}
			}
			if _mwc.webhooks != _|_ {
				webhooks: _mwc.webhooks
			}
		}
	}
}
