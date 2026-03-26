package backup

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	schemas "opmodel.dev/k8up/v1alpha1/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// PreBackupPod Resource Definition
/////////////////////////////////////////////////////////////////

#PreBackupPodResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/resources/backup"
		version:     "v1"
		name:        "pre-backup-pod"
		description: "A K8up PreBackupPod (runs before each backup for consistency)"
		labels: {
			"resource.opmodel.dev/category": "backup"
		}
	}

	#defaults: #PreBackupPodDefaults

	spec: close({preBackupPod: schemas.#PreBackupPodSchema})
}

#PreBackupPod: component.#Component & {
	#resources: {(#PreBackupPodResource.metadata.fqn): #PreBackupPodResource}
}

#PreBackupPodDefaults: schemas.#PreBackupPodSchema
