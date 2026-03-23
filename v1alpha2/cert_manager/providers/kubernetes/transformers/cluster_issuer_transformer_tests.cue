@if(test)

package transformers

// Tests for #ClusterIssuerTransformer

_testClusterIssuerSelfSigned: (#ClusterIssuerTransformer.#transform & {
	#component: {
		metadata: name: "cluster-self-signed"
		spec: clusterIssuer: {
			selfSigned: {}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "cert-manager"
		component: "cluster-self-signed"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "ClusterIssuer"
	metadata: {
		name: "my-release-cluster-self-signed"
		// ClusterIssuer is cluster-scoped: namespace must NOT be present
	}
	spec: {
		selfSigned: {}
	}
}

_testClusterIssuerCA: (#ClusterIssuerTransformer.#transform & {
	#component: {
		metadata: name: "cluster-ca"
		spec: clusterIssuer: {
			ca: {
				secretName: "cluster-root-ca"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "cert-manager"
		component: "cluster-ca"
	}).out
}).output & {
	apiVersion: "cert-manager.io/v1"
	kind:       "ClusterIssuer"
	metadata: {
		name: "my-release-cluster-ca"
	}
	spec: {
		ca: {
			secretName: "cluster-root-ca"
		}
	}
}

_testClusterIssuerAcmeGateway: (#ClusterIssuerTransformer.#transform & {
	#component: {
		metadata: name: "letsencrypt-cluster"
		spec: clusterIssuer: {
			acme: {
				server: "https://acme-v02.api.letsencrypt.org/directory"
				email:  "admin@example.com"
				privateKeySecretRef: {
					name: "letsencrypt-cluster-key"
				}
				solvers: [{
					http01: {
						gatewayHTTPRoute: {
							parentRefs: [{
								name:      "acme-gw"
								namespace: "gateway-system"
								kind:      "Gateway"
							}]
							serviceType: "ClusterIP"
						}
					}
				}]
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "cert-manager"
		component: "letsencrypt-cluster"
	}).out
}).output & {
	kind: "ClusterIssuer"
	spec: {
		acme: {
			server: "https://acme-v02.api.letsencrypt.org/directory"
			email:  "admin@example.com"
			privateKeySecretRef: {
				name: "letsencrypt-cluster-key"
			}
		}
	}
}
