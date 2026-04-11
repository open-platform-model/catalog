package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	security_resources "opmodel.dev/cert_manager/v1alpha1/resources/security@v1"
	certmgrV1 "opmodel.dev/opm/v1alpha1/schemas/kubernetes/certmanager/v1@v1"
)

// #CertificateTransformer converts CertificateResource to a cert-manager Certificate (cert-manager.io/v1)
#CertificateTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/cert-manager/providers/kubernetes/transformers"
		version:     "v1"
		name:        "certificate-transformer"
		description: "Converts CertificateResource to cert-manager Certificate"

		labels: {
			"core.opmodel.dev/resource-type": "certificate"
		}
	}

	requiredLabels: {}

	requiredResources: {
		"opmodel.dev/cert-manager/resources/security/certificate@v1": security_resources.#CertificateResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_cert: #component.spec.certificate

		output: certmgrV1.#Certificate & {
			apiVersion: "cert-manager.io/v1"
			kind:       "Certificate"
			metadata: {
				name:      "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
			}
			spec: {
				secretName: _cert.secretName
				issuerRef: {
					name: _cert.issuerRef.name
					kind: _cert.issuerRef.kind
					if _cert.issuerRef.group != _|_ {
						group: _cert.issuerRef.group
					}
				}
				if _cert.dnsNames != _|_ {
					dnsNames: _cert.dnsNames
				}
				if _cert.ipAddresses != _|_ {
					ipAddresses: _cert.ipAddresses
				}
				if _cert.commonName != _|_ {
					commonName: _cert.commonName
				}
				if _cert.duration != _|_ {
					duration: _cert.duration
				}
				if _cert.renewBefore != _|_ {
					renewBefore: _cert.renewBefore
				}
				if _cert.privateKey != _|_ {
					privateKey: {
						if _cert.privateKey.algorithm != _|_ {
							algorithm: _cert.privateKey.algorithm
						}
						if _cert.privateKey.size != _|_ {
							size: _cert.privateKey.size
						}
						if _cert.privateKey.rotationPolicy != _|_ {
							rotationPolicy: _cert.privateKey.rotationPolicy
						}
					}
				}
				if _cert.usages != _|_ {
					usages: _cert.usages
				}
			}
		}
	}
}
