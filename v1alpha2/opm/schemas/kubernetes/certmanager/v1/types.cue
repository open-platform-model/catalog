// cert-manager v1 Kubernetes types — re-exported from cue.dev/x/crd/cert-manager.io@v0
package v1

import (
	cmv1   "cue.dev/x/crd/cert-manager.io/v1"
	acmev1 "cue.dev/x/crd/cert-manager.io/acme/v1"
)

// From cue.dev/x/crd/cert-manager.io/v1
#Certificate:        cmv1.#Certificate
#CertificateRequest: cmv1.#CertificateRequest
#ClusterIssuer:      cmv1.#ClusterIssuer
#Issuer:             cmv1.#Issuer

// From cue.dev/x/crd/cert-manager.io/acme/v1
#Challenge: acmev1.#Challenge
#Order:     acmev1.#Order
