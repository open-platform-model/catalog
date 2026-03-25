package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/kubernetes/v1alpha1/resources/admission@v1"
)

// #ValidatingWebhookConfigurationTransformer passes native Kubernetes
// ValidatingWebhookConfiguration resources through with OPM context applied.
// ValidatingWebhookConfiguration is cluster-scoped: no namespace.
#ValidatingWebhookConfigurationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/providers/kubernetes/transformers"
		version:     "v1"
		name:        "validatingwebhookconfiguration-transformer"
		description: "Passes native Kubernetes ValidatingWebhookConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "validatingwebhookconfiguration"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ValidatingWebhookConfigurationResource.metadata.fqn): res.#ValidatingWebhookConfigurationResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_vwc:  #component.spec.validatingwebhookconfiguration
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "admissionregistration.k8s.io/v1"
			kind:       "ValidatingWebhookConfiguration"
			metadata: {
				name:   _name
				labels: #context.labels
				if _vwc.metadata != _|_ {
					if _vwc.metadata.annotations != _|_ {
						annotations: _vwc.metadata.annotations
					}
				}
			}
			if _vwc.webhooks != _|_ {
				webhooks: _vwc.webhooks
			}
		}
	}
}
