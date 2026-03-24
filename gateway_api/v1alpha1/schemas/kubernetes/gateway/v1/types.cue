// Gateway API v1 Kubernetes types — re-exported from vendored CRDs (v1.5.1)
package v1

import (
	gwv1 "gateway.networking.k8s.io/gateway/v1"
	gwcv1 "gateway.networking.k8s.io/gatewayclass/v1"
	httpr "gateway.networking.k8s.io/httproute/v1"
	grpcr "gateway.networking.k8s.io/grpcroute/v1"
	refg "gateway.networking.k8s.io/referencegrant/v1"
)

// From gateway.networking.k8s.io/gateway/v1
#Gateway: gwv1.#Gateway

// From gateway.networking.k8s.io/gatewayclass/v1
#GatewayClass: gwcv1.#GatewayClass

// From gateway.networking.k8s.io/httproute/v1
#HTTPRoute: httpr.#HTTPRoute

// From gateway.networking.k8s.io/grpcroute/v1
#GRPCRoute: grpcr.#GRPCRoute

// From gateway.networking.k8s.io/referencegrant/v1
#ReferenceGrant: refg.#ReferenceGrant
