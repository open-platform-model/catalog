package transformers

import (
	core "opmodel.dev/core@v0"
	config_resources "opmodel.dev/resources/config@v0"
	k8scorev1 "opmodel.dev/schemas/kubernetes/core/v1@v0"
)

// SecretTransformer converts Secrets resources to Kubernetes Secrets
#SecretTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "secret-transformer"
		description: "Converts Secrets resources to Kubernetes Secrets"

		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "secret"
		}
	}

	requiredLabels: {}

	// Required resources - Secrets MUST be present
	requiredResources: {
		"opmodel.dev/resources/config@v0#Secrets": config_resources.#SecretsResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_secrets: #component.spec.secrets

		// Generate a K8s Secret for each entry in the map
		output: {
			for secretName, secret in _secrets {
				"\(secretName)": k8scorev1.#Secret & {
					apiVersion: "v1"
					kind:       "Secret"
					metadata: {
						name:      secretName
						namespace: #context.namespace
						labels:    #context.labels
					}
					type: secret.type
					data: secret.data
				}
			}
		}
	}
}

_testSecretTransformer: #SecretTransformer.#transform & {
	#component: _testSecretComponent
	#context:   _testContext
}
