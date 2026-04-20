@if(test)

package transformers

// Test: minimal VirtualDisk passthrough
_testVirtualDiskMinimal: (#VirtualDiskTransformer.#transform & {
	#component: {
		metadata: name: "root-disk"
		spec: virtualDisk: spec: size: "10Gi"
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "root-disk"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VirtualDisk"
	metadata: {
		name:      "rel-root-disk"
		namespace: "vms"
	}
	spec: size: "10Gi"
}
