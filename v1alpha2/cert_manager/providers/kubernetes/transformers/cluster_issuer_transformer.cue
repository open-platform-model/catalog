package transformers

import (
	transformer "opmodel.dev/opm/core/transformer@v1"
	security_resources "opmodel.dev/cert_manager/resources/security@v1"
	certmgrV1 "opmodel.dev/opm/schemas/kubernetes/certmanager/v1@v1"
)

// #ClusterIssuerTransformer converts ClusterIssuerResource to a cert-manager ClusterIssuer (cert-manager.io/v1)
// Note: ClusterIssuer is cluster-scoped — no namespace in metadata.
#ClusterIssuerTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/cert-manager/providers/kubernetes/transformers"
		version:     "v1"
		name:        "cluster-issuer-transformer"
		description: "Converts ClusterIssuerResource to cert-manager ClusterIssuer (cluster-scoped)"

		labels: {
			"core.opmodel.dev/resource-type": "cluster-issuer"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/cert-manager/resources/security/cluster-issuer@v1": security_resources.#ClusterIssuerResource
	}

	optionalResources: {}
	requiredTraits:    {}
	optionalTraits:    {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_clusterIssuer: #component.spec.clusterIssuer

		output: certmgrV1.#ClusterIssuer & {
			apiVersion: "cert-manager.io/v1"
			kind:       "ClusterIssuer"
			metadata: {
				// ClusterIssuer is cluster-scoped: no namespace
				name:   "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"
				labels: #context.labels
			}
			spec: {
				if _clusterIssuer.acme != _|_ {
					acme: {
						server: _clusterIssuer.acme.server
						email:  _clusterIssuer.acme.email
						privateKeySecretRef: {
							name: _clusterIssuer.acme.privateKeySecretRef.name
						}
						if _clusterIssuer.acme.skipTLSVerify != _|_ {
							skipTLSVerify: _clusterIssuer.acme.skipTLSVerify
						}
						if _clusterIssuer.acme.solvers != _|_ {
							solvers: _clusterIssuer.acme.solvers
						}
					}
				}
				if _clusterIssuer.ca != _|_ {
					ca: {
						secretName: _clusterIssuer.ca.secretName
					}
				}
				if _clusterIssuer.selfSigned != _|_ {
					selfSigned: {}
				}
				if _clusterIssuer.vault != _|_ {
					vault: _clusterIssuer.vault
				}
			}
		}
	}
}
