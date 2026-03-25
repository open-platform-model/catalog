@if(test)

package transformers

// Test: minimal PersistentVolume — cluster-scoped, no namespace in output
_testPersistentVolumeMinimal: (#PersistentVolumeTransformer.#transform & {
	#component: {
		metadata: name: "shared-storage"
		spec: persistentvolume: {
			spec: {
				capacity: storage: "10Gi"
				accessModes: ["ReadWriteOnce"]
				hostPath: path: "/mnt/data"
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "shared-storage"}).out
}).output & {
	apiVersion: "v1"
	kind:       "PersistentVolume"
	metadata: name: "my-release-shared-storage"
}
