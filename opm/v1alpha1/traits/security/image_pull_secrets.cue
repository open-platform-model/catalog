package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
	workload_resources "opmodel.dev/opm/v1alpha1/resources/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// ImagePullSecrets Trait Definition
////
//// References pre-existing K8s Secrets (type kubernetes.io/dockerconfigjson)
//// that the kubelet uses to authenticate to private container registries
//// when pulling images for any container in the pod.
/////////////////////////////////////////////////////////////////

#ImagePullSecretsTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/traits/security"
		version:     "v1"
		name:        "image-pull-secrets"
		description: "Reference K8s Secrets used to authenticate to private container registries"
		labels: {
			"trait.opmodel.dev/category": "security"
		}
	}

	appliesTo: [workload_resources.#ContainerResource]

	#defaults: []

	spec: close({imagePullSecrets: schemas.#ImagePullSecretsSchema})
}

#ImagePullSecrets: component.#Component & {
	#traits: {(#ImagePullSecretsTrait.metadata.fqn): #ImagePullSecretsTrait}
}
