@if(test)

package schemas

// =============================================================================
// Config Schema Tests
// =============================================================================

// ── ConfigMapSchema ──────────────────────────────────────────────

_testConfigMapBasic: #ConfigMapSchema & {
	data: {
		"app.conf":   "key=value\nother=thing"
		"nginx.conf": "server { listen 80; }"
	}
}

// ── SecretSchema ─────────────────────────────────────────────────

_testSecretDefault: #SecretSchema & {
	data: {
		"password": "c2VjcmV0"
	}
	// type defaults to "Opaque"
}

_testSecretTLS: #SecretSchema & {
	type: "kubernetes.io/tls"
	data: {
		"tls.crt": "base64cert"
		"tls.key": "base64key"
	}
}
