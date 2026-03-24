@if(test)

package transformers

// Combinatorial matrix for #CertificateTransformer
//
// Optional fields tested:
//   C1: dnsNames
//   C2: ipAddresses
//   C3: commonName
//   C4: duration + renewBefore (lifecycle pair)
//   C5: privateKey (algorithm, size, rotationPolicy)
//   C6: usages
//
// Coverage: 9 combinations from 2^6=64 total
// Strategy: each field alone (6) + key pairs (2) + kitchen sink (1)

// [all=-] Absolute minimal — secretName + issuerRef only
_matrixCert_minimal: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: {name: "r-cert", namespace: "ns"}
	spec: {
		secretName: "my-tls"
		issuerRef: {name: "ca", kind: "ClusterIssuer"}
	}
}

// [C1=✓] dnsNames only
_matrixCert_dnsNamesOnly: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			dnsNames: ["app.example.com", "www.example.com"]
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: dnsNames: ["app.example.com", "www.example.com"]
}

// [C2=✓] ipAddresses only
_matrixCert_ipAddressesOnly: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			ipAddresses: ["10.0.0.1", "192.168.1.1"]
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: ipAddresses: ["10.0.0.1", "192.168.1.1"]
}

// [C3=✓] commonName only
_matrixCert_commonNameOnly: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			commonName: "my-service.ns.svc.cluster.local"
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: commonName: "my-service.ns.svc.cluster.local"
}

// [C4=✓] duration + renewBefore lifecycle pair
_matrixCert_lifetimePair: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			duration:    "2160h"
			renewBefore: "720h"
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: {
		duration:    "2160h"
		renewBefore: "720h"
	}
}

// [C5=✓ RSA] privateKey with RSA algorithm
_matrixCert_privateKeyRsa: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			privateKey: {algorithm: "RSA", size: 4096, rotationPolicy: "Always"}
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: privateKey: {algorithm: "RSA", size: 4096, rotationPolicy: "Always"}
}

// [C5=✓ ECDSA] privateKey with ECDSA algorithm
_matrixCert_privateKeyEcdsa: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			privateKey: {algorithm: "ECDSA", size: 256}
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: privateKey: {algorithm: "ECDSA", size: 256}
}

// [C6=✓] usages only
_matrixCert_usagesOnly: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "cert"
		spec: certificate: {
			secretName: "my-tls"
			issuerRef: {name: "ca", kind: "ClusterIssuer"}
			usages: ["server auth", "client auth"]
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "cert"
	}).out
}).output & {
	spec: usages: ["server auth", "client auth"]
}

// [C1=✓, C3=✓, C4=✓, C5=✓ ECDSA, C6=✓] Kitchen sink — all optional fields
_matrixCert_kitchenSink: (#CertificateTransformer.#transform & {
	#component: {
		metadata: name: "full-cert"
		spec: certificate: {
			secretName: "full-tls"
			commonName: "full.example.com"
			dnsNames: ["full.example.com", "alt.example.com"]
			ipAddresses: ["10.1.2.3"]
			duration:    "8760h"
			renewBefore: "720h"
			issuerRef: {name: "letsencrypt", kind: "ClusterIssuer"}
			privateKey: {algorithm: "ECDSA", size: 384, rotationPolicy: "Always"}
			usages: ["digital signature", "key encipherment", "server auth"]
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "prod"
		component: "full-cert"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: {name: "r-full-cert", namespace: "prod"}
	spec: {
		secretName: "full-tls"
		commonName: "full.example.com"
		dnsNames: ["full.example.com", "alt.example.com"]
		ipAddresses: ["10.1.2.3"]
		duration:    "8760h"
		renewBefore: "720h"
		issuerRef: {name: "letsencrypt", kind: "ClusterIssuer"}
		privateKey: {algorithm: "ECDSA", size: 384, rotationPolicy: "Always"}
		usages: ["digital signature", "key encipherment", "server auth"]
	}
}
