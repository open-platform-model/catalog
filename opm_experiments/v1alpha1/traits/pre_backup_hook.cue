// Package traits holds experimental #Trait definitions.
//
// Definitions here are not stable and may change shape, be renamed,
// or be removed without notice. See README.md for graduation criteria.
package traits

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	storage_resources "opmodel.dev/opm/v1alpha1/resources/storage@v1"
)

/////////////////////////////////////////////////////////////////
//// PreBackupHookTrait — per-component quiescing hook
/////////////////////////////////////////////////////////////////

// #PreBackupHookTrait: declares a quiescing command that K8up should run as a
// PreBackupPod before backing up the component. The K8up PreBackupPod
// transformer produces one PreBackupPod CR per component carrying this trait.
//
// The trait is per-component: any backup policy that targets the component
// picks up its hook automatically. Components without persistent state do not
// need this trait.
#PreBackupHookTrait: prim.#Trait & {
	metadata: {
		modulePath:  "opmodel.dev/opm-experiments/v1alpha1/traits"
		version:     "v1"
		name:        "pre-backup-hook"
		description: "Runs a command as a K8up PreBackupPod before backing up the component (experimental)"
		labels: {
			"trait.opmodel.dev/category": "data"
		}
	}

	// Apply to components that carry a Volume resource — the hook is only
	// meaningful when there is persistent state to quiesce.
	appliesTo: [storage_resources.#VolumesResource]

	#defaults: #PreBackupHookDefaults

	spec: close({preBackupHook: #PreBackupHookSchema})
}

// #PreBackupHook: convenience wrapper that attaches the trait to a component.
#PreBackupHook: component.#Component & {
	#traits: {(#PreBackupHookTrait.metadata.fqn): #PreBackupHookTrait}
}

// #PreBackupHookDefaults: no meaningful defaults — the module author must
// specify image + command.
#PreBackupHookDefaults: #PreBackupHookSchema

// #PreBackupHookSchema describes the hook container.
//
//   - image + command run as a K8s Pod spec.
//   - volumeMount (optional) mounts one of the component's own volumes into
//     the hook container. Useful for on-disk quiescing (SQLite WAL checkpoint,
//     pg_dump into the PVC). Not needed for hooks that talk over the network
//     (RCON, HTTP, etc.).
#PreBackupHookSchema: {
	image!: string
	command!: [...string]

	volumeMount?: {
		volume!:   string // must reference a volume name on the component
		mountPath: *"/data" | string
	}
}
