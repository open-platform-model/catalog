package admission

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// MutatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// #MutatingWebhookConfigurationResource defines a native Kubernetes
// MutatingWebhookConfiguration as an OPM resource.
// Use this to register admission webhooks that mutate resource requests.
#MutatingWebhookConfigurationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/admission"
		version:     "v1"
		name:        "mutatingwebhookconfiguration"
		description: "A native Kubernetes MutatingWebhookConfiguration resource"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	#defaults: #MutatingWebhookConfigurationDefaults

	spec: close({mutatingwebhookconfiguration: schemas.#MutatingWebhookConfigurationSchema})
}

#MutatingWebhookConfiguration: component.#Component & {
	#resources: {(#MutatingWebhookConfigurationResource.metadata.fqn): #MutatingWebhookConfigurationResource}
}

#MutatingWebhookConfigurationDefaults: schemas.#MutatingWebhookConfigurationSchema & {}
