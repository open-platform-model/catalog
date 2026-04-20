@if(test)

package transformers

// Test: minimal VMPool passthrough
_testVMPoolMinimal: (#VMPoolTransformer.#transform & {
	#component: {
		metadata: name: "api-pool"
		spec: vmPool: spec: replicas: 3
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "api-pool"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VMPool"
	metadata: {
		name:      "rel-api-pool"
		namespace: "vms"
	}
	spec: replicas: 3
}
