@if(test)

package transformers

// Test: minimal VirtualDiskSnapshot passthrough
_testVirtualDiskSnapshotMinimal: (#VirtualDiskSnapshotTransformer.#transform & {
	#component: {
		metadata: name: "root-snap"
		spec: virtualDiskSnapshot: spec: source: name: "root-disk"
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "root-snap"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VirtualDiskSnapshot"
	metadata: {
		name:      "rel-root-snap"
		namespace: "vms"
	}
	spec: source: name: "root-disk"
}
