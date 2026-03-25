@if(test)

package transformers

// Test: minimal PersistentVolumeClaim with required fields
_testPersistentVolumeClaimMinimal: (#PersistentVolumeClaimTransformer.#transform & {
	#component: {
		metadata: name: "data"
		spec: persistentvolumeclaim: {
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "1Gi"
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "data"}).out
}).output & {
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "my-release-data"
		namespace: "default"
	}
}
