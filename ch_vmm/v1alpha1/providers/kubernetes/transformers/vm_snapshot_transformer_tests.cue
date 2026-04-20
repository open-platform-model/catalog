@if(test)

package transformers

// Test: minimal VMSnapShot passthrough
_testVMSnapShotMinimal: (#VMSnapShotTransformer.#transform & {
	#component: {
		metadata: name: "web-snap"
		spec: vmSnapShot: spec: vmName: "web-vm"
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "web-snap"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VMSnapShot"
	metadata: {
		name:      "rel-web-snap"
		namespace: "vms"
	}
	spec: vmName: "web-vm"
}
