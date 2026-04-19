package transformers

import (
	"strings"

	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	exp_traits "opmodel.dev/opm_experiments/v1alpha1/traits@v1"
)

/////////////////////////////////////////////////////////////////
//// K8upPreBackupHookTransformer — consumes #PreBackupHookTrait
/////////////////////////////////////////////////////////////////

// #K8upPreBackupHookTransformer builds a K8up PreBackupPod CR from a matched
// #PreBackupHookTrait on a component. One PreBackupPod per component
// carrying the trait.
//
// The output mounts the referenced volume (when volumeMount is set) by
// pulling the PVC name from the component's spec.volumes map.
#K8upPreBackupHookTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/opm-experiments/v1alpha1/providers/kubernetes/transformers"
		version:     "v0"
		name:        "k8up-pre-backup-hook-transformer"
		description: "Generates a K8up PreBackupPod CR from #PreBackupHookTrait (experimental)"
		labels: {
			"core.opmodel.dev/resource-category": "backup"
			"core.opmodel.dev/resource-type":     "pre-backup-pod"
			"transformer.opmodel.dev/stability":  "experimental"
		}
	}

	requiredLabels: {}
	requiredResources: {}
	optionalResources: {}
	requiredTraits: {
		(exp_traits.#PreBackupHookTrait.metadata.fqn): exp_traits.#PreBackupHookTrait
	}
	optionalTraits: {}
	requiredDirectives: {}
	optionalDirectives: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_hook: #component.spec.preBackupHook
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)-pre-backup"

		// Resolve the volume reference to a PVC name when volumeMount is set.
		// Convention: PVC name = "{release}-{component}-{volume}"
		_pvcName: string
		if _hook.volumeMount != _|_ {
			_pvcName: "\(#context.#moduleReleaseMetadata.name)-\(#context.#componentMetadata.name)-\(_hook.volumeMount.volume)"
		}

		output: {
			apiVersion: "k8up.io/v1"
			kind:       "PreBackupPod"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
			}
			spec: {
				// K8up's backupCommand is a single string it executes in the pod.
				backupCommand: strings.Join(_hook.command, " ")

				pod: spec: {
					containers: [{
						name:    "pre-backup"
						image:   _hook.image
						command: _hook.command
						if _hook.volumeMount != _|_ {
							volumeMounts: [{
								name:      "data"
								mountPath: _hook.volumeMount.mountPath
							}]
						}
					}]
					if _hook.volumeMount != _|_ {
						volumes: [{
							name: "data"
							persistentVolumeClaim: claimName: _pvcName
						}]
					}
				}
			}
		}
	}
}
