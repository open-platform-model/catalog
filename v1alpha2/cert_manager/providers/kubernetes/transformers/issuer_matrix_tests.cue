@if(test)

package transformers

// Combinatorial matrix for #IssuerTransformer and #ClusterIssuerTransformer
//
// Issuer types are mutually exclusive: acme | ca | selfSigned | vault
// ACME has solver variants: none | ingress | gatewayHTTPRoute
//
// Coverage: 6 combinations
//   Issuer: selfSigned, CA, ACME-basic, ACME-ingress, ACME-gateway
//   ClusterIssuer: selfSigned (cluster-scoped namespace omission check)

// Issuer: selfSigned
_matrixIssuer_selfSigned: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "ss"
		spec: issuer: {selfSigned: {}}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "ss"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: {name: "r-ss", namespace: "ns"}
	spec: {selfSigned: {}}
}

// Issuer: CA
_matrixIssuer_ca: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "ca"
		spec: issuer: {ca: {secretName: "root-ca"}}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "ca"
	}).out
}).output & {
	kind: "Issuer"
	spec: {ca: {secretName: "root-ca"}}
}

// Issuer: ACME basic (no solver)
_matrixIssuer_acmeBasic: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "acme"
		spec: issuer: {
			acme: {
				server: "https://acme-staging-v02.api.letsencrypt.org/directory"
				email:  "ops@example.com"
				privateKeySecretRef: {name: "acme-key"}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "acme"
	}).out
}).output & {
	kind: "Issuer"
	spec: acme: {
		server: "https://acme-staging-v02.api.letsencrypt.org/directory"
		email:  "ops@example.com"
		privateKeySecretRef: {name: "acme-key"}
	}
}

// Issuer: ACME + HTTP01 ingress solver
_matrixIssuer_acmeIngressSolver: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "acme-ingress"
		spec: issuer: {
			acme: {
				server: "https://acme-v02.api.letsencrypt.org/directory"
				email:  "ops@example.com"
				privateKeySecretRef: {name: "acme-key"}
				solvers: [{
					http01: {ingress: {ingressClassName: "nginx"}}
				}]
			}
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "acme-ingress"
	}).out
}).output & {
	kind: "Issuer"
	spec: acme: {
		solvers: [{
			http01: {ingress: {ingressClassName: "nginx"}}
		}]
	}
}

// Issuer: ACME + HTTP01 Gateway solver
_matrixIssuer_acmeGatewaySolver: (#IssuerTransformer.#transform & {
	#component: {
		metadata: name: "acme-gw"
		spec: issuer: {
			acme: {
				server: "https://acme-v02.api.letsencrypt.org/directory"
				email:  "ops@example.com"
				privateKeySecretRef: {name: "acme-key"}
				solvers: [{
					http01: {
						gatewayHTTPRoute: {
							parentRefs: [{name: "acme-gw", namespace: "gateway", kind: "Gateway"}]
							serviceType: "ClusterIP"
						}
					}
				}]
			}
		}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "ns"
		component: "acme-gw"
	}).out
}).output & {
	kind: "Issuer"
	spec: acme: {
		solvers: [{
			http01: {
				gatewayHTTPRoute: {
					serviceType: "ClusterIP"
				}
			}
		}]
	}
}

// ClusterIssuer: selfSigned — verifies NO namespace in output
_matrixClusterIssuer_selfSigned_noNamespace: (#ClusterIssuerTransformer.#transform & {
	#component: {
		metadata: name: "cluster-ss"
		spec: clusterIssuer: {selfSigned: {}}
	}
	#context: (#TestCtx & {
		release:   "r"
		namespace: "cert-manager"
		component: "cluster-ss"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "ClusterIssuer"
	metadata: {
		name: "r-cluster-ss"
		// namespace intentionally absent — ClusterIssuer is cluster-scoped
	}
	spec: {selfSigned: {}}
}
