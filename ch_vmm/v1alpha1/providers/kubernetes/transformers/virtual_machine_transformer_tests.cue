@if(test)

package transformers

// Test: minimal VirtualMachine with instance
_testVirtualMachineMinimal: (#VirtualMachineTransformer.#transform & {
	#component: {
		metadata: name: "web-vm"
		spec: virtualMachine: {
			spec: {
				instance: {
					kernel: {
						cmdline: "console=ttyS0"
						image:   "quay.io/containerdisks/ubuntu:22.04"
					}
				}
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "vms", component: "web-vm"}).out
}).output & {
	apiVersion: "cloudhypervisor.quill.today/v1beta1"
	kind:       "VirtualMachine"
	metadata: {
		name:      "my-release-web-vm"
		namespace: "vms"
	}
	spec: instance: kernel: image: "quay.io/containerdisks/ubuntu:22.04"
}
