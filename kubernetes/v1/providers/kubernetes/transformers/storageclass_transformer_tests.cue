@if(test)

package transformers

// Test: minimal StorageClass — cluster-scoped, no namespace in output
_testStorageClassMinimal: (#StorageClassTransformer.#transform & {
	#component: {
		metadata: name: "fast"
		spec: storageclass: {
			provisioner: "kubernetes.io/no-provisioner"
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "fast"}).out
}).output & {
	apiVersion: "storage.k8s.io/v1"
	kind:       "StorageClass"
	metadata: name: "my-release-fast"
}
