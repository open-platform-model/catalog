@if(test)

package transformers

// Test: minimal VMRestoreSpec passthrough
_testVMRestoreSpecMinimal: (#VMRestoreSpecTransformer.#transform & {
	#component: {
		metadata: name: "restore-web"
		spec: vmRestoreSpec: spec: snapshotName: "web-snap"
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "restore-web"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VMRestoreSpec"
	metadata: {
		name:      "rel-restore-web"
		namespace: "vms"
	}
	spec: snapshotName: "web-snap"
}
