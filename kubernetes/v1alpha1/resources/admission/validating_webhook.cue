package admission

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ValidatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// #ValidatingWebhookConfigurationResource defines a native Kubernetes
// ValidatingWebhookConfiguration as an OPM resource.
// Use this to register admission webhooks that validate resource requests.
#ValidatingWebhookConfigurationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/admission"
		version:     "v1"
		name:        "validatingwebhookconfiguration"
		description: "A native Kubernetes ValidatingWebhookConfiguration resource"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	#defaults: #ValidatingWebhookConfigurationDefaults

	spec: close({validatingwebhookconfiguration: schemas.#ValidatingWebhookConfigurationSchema})
}

#ValidatingWebhookConfigurationComponent: component.#Component & {
	#resources: {(#ValidatingWebhookConfigurationResource.metadata.fqn): #ValidatingWebhookConfigurationResource}
}

#ValidatingWebhookConfigurationDefaults: schemas.#ValidatingWebhookConfigurationSchema & {}
