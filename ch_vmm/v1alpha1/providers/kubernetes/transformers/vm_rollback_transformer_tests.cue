@if(test)

package transformers

// Test: minimal VMRollback passthrough
_testVMRollbackMinimal: (#VMRollbackTransformer.#transform & {
	#component: {
		metadata: name: "rollback-web"
		spec: vmRollback: spec: vmName: "web-vm"
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "rollback-web"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VMRollback"
	metadata: {
		name:      "rel-rollback-web"
		namespace: "vms"
	}
	spec: vmName: "web-vm"
}
