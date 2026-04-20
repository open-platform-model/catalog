package kubernetes

import (
	provider "opmodel.dev/core/v1alpha1/provider@v1"
	ch_transformers "opmodel.dev/ch_vmm/v1alpha1/providers/kubernetes/transformers"
)

// ChVmmKubernetesProvider transforms ch-vmm components to Kubernetes native resources
// (cloudhypervisor.quill.today/v1beta1 CRs — pure passthrough with OPM context applied).
#Provider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		description: "Transforms ch-vmm components to Kubernetes native resources"
		version:     "0.1.0"

		labels: {
			"core.opmodel.dev/format":   "kubernetes"
			"core.opmodel.dev/platform": "container-orchestrator"
		}
	}

	// Transformer registry - maps transformer FQNs to transformer definitions
	#transformers: {
		(ch_transformers.#VirtualMachineTransformer.metadata.fqn):          ch_transformers.#VirtualMachineTransformer
		(ch_transformers.#VirtualDiskTransformer.metadata.fqn):             ch_transformers.#VirtualDiskTransformer
		(ch_transformers.#VirtualDiskSnapshotTransformer.metadata.fqn):     ch_transformers.#VirtualDiskSnapshotTransformer
		(ch_transformers.#VirtualMachineMigrationTransformer.metadata.fqn): ch_transformers.#VirtualMachineMigrationTransformer
		(ch_transformers.#VMPoolTransformer.metadata.fqn):                  ch_transformers.#VMPoolTransformer
		(ch_transformers.#VMRestoreSpecTransformer.metadata.fqn):           ch_transformers.#VMRestoreSpecTransformer
		(ch_transformers.#VMRollbackTransformer.metadata.fqn):              ch_transformers.#VMRollbackTransformer
		(ch_transformers.#VMSetTransformer.metadata.fqn):                   ch_transformers.#VMSetTransformer
		(ch_transformers.#VMSnapShotTransformer.metadata.fqn):              ch_transformers.#VMSnapShotTransformer
	}
}
