@if(test)

package transformers

// Test: minimal VirtualMachineMigration passthrough
_testVirtualMachineMigrationMinimal: (#VirtualMachineMigrationTransformer.#transform & {
	#component: {
		metadata: name: "evict-web"
		spec: virtualMachineMigration: spec: vmName: "web-vm"
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "evict-web"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VirtualMachineMigration"
	metadata: {
		name:      "rel-evict-web"
		namespace: "vms"
	}
	spec: vmName: "web-vm"
}
