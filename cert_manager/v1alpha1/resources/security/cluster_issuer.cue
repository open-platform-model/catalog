package security

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/opm/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ClusterIssuer Resource Definition
/////////////////////////////////////////////////////////////////

#ClusterIssuerResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/cert-manager/resources/security"
		version:     "v1"
		name:        "cluster-issuer"
		description: "A cert-manager ClusterIssuer (cluster-scoped certificate authority)"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	#defaults: #ClusterIssuerDefaults

	spec: close({clusterIssuer: schemas.#ClusterIssuerSchema})
}

#ClusterIssuer: component.#Component & {
	#resources: {(#ClusterIssuerResource.metadata.fqn): #ClusterIssuerResource}
}

#ClusterIssuerDefaults: schemas.#ClusterIssuerSchema
