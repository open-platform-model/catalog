package backup

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/k8up/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Restore Resource Definition
/////////////////////////////////////////////////////////////////

#RestoreResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/resources/backup"
		version:     "v1"
		name:        "restore"
		description: "A K8up Restore (restore from restic repository)"
		labels: {
			"resource.opmodel.dev/category": "backup"
		}
	}

	#defaults: #RestoreDefaults

	spec: close({restore: schemas.#RestoreSchema})
}

#Restore: component.#Component & {
	#resources: {(#RestoreResource.metadata.fqn): #RestoreResource}
}

#RestoreDefaults: schemas.#RestoreSchema
