package backup

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/k8up/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Backup Resource Definition
/////////////////////////////////////////////////////////////////

#BackupResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/resources/backup"
		version:     "v1"
		name:        "backup"
		description: "A K8up one-off Backup"
		labels: {
			"resource.opmodel.dev/category": "backup"
		}
	}

	#defaults: #BackupDefaults

	spec: close({backup: schemas.#BackupSchema})
}

#Backup: component.#Component & {
	#resources: {(#BackupResource.metadata.fqn): #BackupResource}
}

#BackupDefaults: schemas.#BackupSchema
