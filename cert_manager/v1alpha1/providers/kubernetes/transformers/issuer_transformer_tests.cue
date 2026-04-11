@if(test)

package transformers

// Tests for #IssuerTransformer

_testIssuerSelfSigned: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "self-signed"
		spec: issuer: {
			selfSigned: {}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "self-signed"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: {
		name:      "my-release-self-signed"
		namespace: "default"
	}
	spec: {
		selfSigned: {}
	}
}

_testIssuerCA: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "ca-issuer"
		spec: issuer: {
			ca: {
				secretName: "root-ca-secret"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "cert-manager"
		component: "ca-issuer"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: {
		name:      "my-release-ca-issuer"
		namespace: "cert-manager"
	}
	spec: {
		ca: {
			secretName: "root-ca-secret"
		}
	}
}

_testIssuerAcme: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "letsencrypt"
		spec: issuer: {
			acme: {
				server: "https://acme-v02.api.letsencrypt.org/directory"
				email:  "admin@example.com"
				privateKeySecretRef: {
					name: "letsencrypt-private-key"
				}
				solvers: [{
					http01: {
						ingress: {
							ingressClassName: "nginx"
						}
					}
				}]
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "letsencrypt"
	}).out
}).output & {
	spec: {
		acme: {
			server: "https://acme-v02.api.letsencrypt.org/directory"
			email:  "admin@example.com"
			privateKeySecretRef: {
				name: "letsencrypt-private-key"
			}
		}
	}
}
