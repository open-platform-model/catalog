package config

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ConfigMap Resource Definition
/////////////////////////////////////////////////////////////////

// #ConfigMapResource defines a native Kubernetes ConfigMap as an OPM resource.
// Use this for environment config, application settings, and non-sensitive key-value data.
#ConfigMapResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/config"
		version:     "v1"
		name:        "configmap"
		description: "A native Kubernetes ConfigMap resource"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	#defaults: #ConfigMapDefaults

	spec: close({configmap: schemas.#ConfigMapSchema})
}

#ConfigMapComponent: component.#Component & {
	#resources: {(#ConfigMapResource.metadata.fqn): #ConfigMapResource}
}

#ConfigMapDefaults: schemas.#ConfigMapSchema & {}
