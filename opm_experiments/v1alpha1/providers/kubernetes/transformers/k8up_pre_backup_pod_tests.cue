@if(test)

package transformers

// =============================================================================
// K8upPreBackupHookTransformer Tests
// =============================================================================
//
// Run: cue vet -t test ./providers/kubernetes/transformers/...
// Or:  task test:opm_experiments   (from catalog/)

// Test: Hook with a volumeMount mounts the resolved PVC name.
// Asserts: name convention, container image/command, backupCommand joined
//          with spaces, volume mount + pod volume pointing at the resolved
//          PVC claim name.
_testPreBackupPodWithVolume: (#K8upPreBackupHookTransformer.#transform & {
	#component: {
		metadata: name: "jellyfin"
		spec: preBackupHook: {
			image: "alpine:3.21"
			command: ["sh", "-c", "sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)'"]
			volumeMount: {
				volume:    "config"
				mountPath: "/config"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "jellyfin"
		namespace: "media"
		component: "jellyfin"
	}).out
}).output & {
	apiVersion: "k8up.io/v1"
	kind:       "PreBackupPod"
	metadata: {
		name:      "jellyfin-jellyfin-pre-backup"
		namespace: "media"
	}
	spec: {
		backupCommand: "sh -c sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)'"
		pod: spec: {
			containers: [{
				name:  "pre-backup"
				image: "alpine:3.21"
				command: ["sh", "-c", "sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)'"]
				volumeMounts: [{
					name:      "data"
					mountPath: "/config"
				}]
			}]
			volumes: [{
				name: "data"
				persistentVolumeClaim: claimName: "jellyfin-jellyfin-config"
			}]
		}
	}
}

// Test: Hook without a volumeMount omits volumes from the pod spec.
// Asserts: container defined, no volumeMounts, no volumes (network-only hook).
_testPreBackupPodNetworkHook: (#K8upPreBackupHookTransformer.#transform & {
	#component: {
		metadata: name: "minecraft"
		spec: preBackupHook: {
			image: "itzg/mc-monitor:0.12"
			command: [
				"mc-monitor", "execute-rcon",
				"--host", "localhost",
				"--port", "25575",
				"--command", "save-all flush",
			]
		}
	}
	#context: (#TestCtx & {
		release:   "mc"
		namespace: "games"
		component: "minecraft"
	}).out
}).output & {
	metadata: name: "mc-minecraft-pre-backup"
	spec: {
		backupCommand: "mc-monitor execute-rcon --host localhost --port 25575 --command save-all flush"
		pod: spec: containers: [{
			name:  "pre-backup"
			image: "itzg/mc-monitor:0.12"
		}]
	}
}
