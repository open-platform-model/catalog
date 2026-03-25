package config

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/kubernetes/v1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Secret Resource Definition
/////////////////////////////////////////////////////////////////

// #SecretResource defines a native Kubernetes Secret as an OPM resource.
// Use this for sensitive data such as passwords, tokens, and TLS certificates.
#SecretResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/kubernetes/resources/config"
		version:     "v1"
		name:        "secret"
		description: "A native Kubernetes Secret resource"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	#defaults: #SecretDefaults

	spec: close({secret: schemas.#SecretSchema})
}

#Secret: component.#Component & {
	#resources: {(#SecretResource.metadata.fqn): #SecretResource}
}

#SecretDefaults: schemas.#SecretSchema & {}
