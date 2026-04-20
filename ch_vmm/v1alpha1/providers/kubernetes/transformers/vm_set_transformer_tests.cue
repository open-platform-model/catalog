@if(test)

package transformers

// Test: minimal VMSet passthrough
_testVMSetMinimal: (#VMSetTransformer.#transform & {
	#component: {
		metadata: name: "api-set"
		spec: vmSet: spec: replicas: 2
	}
	#context: (#TestCtx & {release: "rel", namespace: "vms", component: "api-set"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VMSet"
	metadata: {
		name:      "rel-api-set"
		namespace: "vms"
	}
	spec: replicas: 2
}
