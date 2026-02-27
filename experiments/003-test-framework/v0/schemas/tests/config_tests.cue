@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ConfigMapSchema
	// =========================================================================

	"#ConfigMapSchema": [
		{
			name:       "basic with data"
			definition: #ConfigMapSchema
			input: data: {
				"app.conf":   "key=value\nother=thing"
				"nginx.conf": "server { listen 80; }"
			}
			assert: valid: true
		},
		{
			name:       "empty data"
			definition: #ConfigMapSchema
			input: data: {}
			assert: valid: true
		},
	]

	// =========================================================================
	// #SecretSchema
	// =========================================================================

	"#SecretSchema": [
		{
			name:       "default opaque"
			definition: #SecretSchema
			input: data: password: "c2VjcmV0"
			assert: valid: true
		},
		{
			name:       "TLS type"
			definition: #SecretSchema
			input: {
				type: "kubernetes.io/tls"
				data: {
					"tls.crt": "base64cert"
					"tls.key": "base64key"
				}
			}
			assert: valid: true
		},
	]
}
