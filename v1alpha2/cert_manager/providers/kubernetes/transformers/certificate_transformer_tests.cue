@if(test)

package transformers

// Tests for #CertificateTransformer

_testCertificateMinimal: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "web-cert"
		spec: certificate: {
			secretName: "web-tls"
			issuerRef: {
				name: "letsencrypt"
				kind: "ClusterIssuer"
			}
			dnsNames: ["example.com"]
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "web-cert"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: {
		name:      "my-release-web-cert"
		namespace: "default"
	}
	spec: {
		secretName: "web-tls"
		issuerRef: {
			name: "letsencrypt"
			kind: "ClusterIssuer"
		}
		dnsNames: ["example.com"]
	}
}

_testCertificateWithDuration: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "api-cert"
		spec: certificate: {
			secretName: "api-tls"
			issuerRef: {
				name: "internal-ca"
				kind: "Issuer"
			}
			dnsNames: ["api.example.com", "api.internal.example.com"]
			duration:    "2160h"
			renewBefore: "360h"
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "production"
		component: "api-cert"
	}).out
}).output & {
	spec: {
		secretName:  "api-tls"
		duration:    "2160h"
		renewBefore: "360h"
		dnsNames: ["api.example.com", "api.internal.example.com"]
	}
}

_testCertificateWithPrivateKey: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "ecdsa-cert"
		spec: certificate: {
			secretName: "ecdsa-tls"
			issuerRef: {
				name: "letsencrypt"
				kind: "ClusterIssuer"
			}
			dnsNames: ["ecdsa.example.com"]
			privateKey: {
				algorithm:      "ECDSA"
				size:           256
				rotationPolicy: "Always"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "ecdsa-cert"
	}).out
}).output & {
	spec: {
		privateKey: {
			algorithm:      "ECDSA"
			size:           256
			rotationPolicy: "Always"
		}
	}
}

_testCertificateWithUsages: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "client-cert"
		spec: certificate: {
			secretName: "client-tls"
			issuerRef: {
				name: "internal-ca"
				kind: "Issuer"
			}
			commonName: "my-service-account"
			usages: ["digital signature", "key encipherment", "client auth"]
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "client-cert"
	}).out
}).output & {
	spec: {
		commonName: "my-service-account"
		usages: ["digital signature", "key encipherment", "client auth"]
	}
}
