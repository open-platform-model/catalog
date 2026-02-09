package transformers

import (
	core "opmodel.dev/core@v0"
	config_resources "opmodel.dev/resources/config@v0"
)

// SecretTransformer converts Secret resources to Kubernetes Secrets
#SecretTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "secret-transformer"
		description: "Converts Secret resources to Kubernetes Secrets"

		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "secret"
		}
	}

	requiredLabels: {}

	// Required resources - Secret MUST be present
	requiredResources: {
		"opmodel.dev/resources/config@v0#Secret": config_resources.#SecretResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_secret: #component.spec.secret

		output: {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace
				labels:    #context.labels
			}
			type: _secret.type
			data: _secret.data
		}
	}
}

_testSecretTransformer: #SecretTransformer.#transform & {
	#component: _testSecretComponent
	#context:   _testContext
}
