@if(test)

package config

// =============================================================================
// Secret Resource Tests
// =============================================================================

// Test: SecretsResource definition structure
_testSecretsResourceDef: #SecretsResource & {
	metadata: {
		apiVersion: "opmodel.dev/resources/config@v0"
		name:       "secrets"
		fqn:        "opmodel.dev/resources/config@v0#Secrets"
	}
}

// Test: Secrets component helper with default type
_testSecretsComponent: #Secrets & {
	metadata: name: "secret-test"
	spec: secrets: {
		"db-credentials": {
			data: {
				"username": "YWRtaW4="
				"password": "c2VjcmV0"
			}
		}
	}
}

// Test: Secret with explicit TLS type
_testSecretsTLS: #Secrets & {
	metadata: name: "tls-secret-test"
	spec: secrets: {
		"tls-cert": {
			type: "kubernetes.io/tls"
			data: {
				"tls.crt": "base64cert"
				"tls.key": "base64key"
			}
		}
	}
}

// Test: SecretsDefaults type is Opaque
_testSecretsDefaults: #SecretsDefaults & {
	type: "Opaque"
	data: "key": "value"
}
