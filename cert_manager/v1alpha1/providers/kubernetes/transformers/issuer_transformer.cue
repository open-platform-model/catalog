package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	security_resources "opmodel.dev/cert_manager/v1alpha1/resources/security@v1"
	certmgrV1 "opmodel.dev/opm/v1alpha1/schemas/kubernetes/certmanager/v1@v1"
)

// #IssuerTransformer converts IssuerResource to a cert-manager Issuer (cert-manager.io/v1)
#IssuerTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/cert-manager/providers/kubernetes/transformers"
		version:     "v1"
		name:        "issuer-transformer"
		description: "Converts IssuerResource to cert-manager Issuer (namespace-scoped)"

		labels: {
			"core.opmodel.dev/resource-type": "issuer"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/cert-manager/resources/security/issuer@v1": security_resources.#IssuerResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_issuer: #component.spec.issuer

		output: certmgrV1.#Issuer & {
			apiVersion: "cert-manager.io/v1"
			kind:       "Issuer"
			metadata: {
				name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
			}
			spec: {
				if _issuer.acme != _|_ {
					acme: {
						server: _issuer.acme.server
						email:  _issuer.acme.email
						privateKeySecretRef: {
							name: _issuer.acme.privateKeySecretRef.name
						}
						if _issuer.acme.skipTLSVerify != _|_ {
							skipTLSVerify: _issuer.acme.skipTLSVerify
						}
						if _issuer.acme.solvers != _|_ {
							solvers: _issuer.acme.solvers
						}
					}
				}
				if _issuer.ca != _|_ {
					ca: {
						secretName: _issuer.ca.secretName
					}
				}
				if _issuer.selfSigned != _|_ {
					selfSigned: {}
				}
				if _issuer.vault != _|_ {
					vault: _issuer.vault
				}
			}
		}
	}
}
