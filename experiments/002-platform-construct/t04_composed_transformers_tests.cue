@if(test)

package platform_construct

// T04 — #composedTransformers aggregates every enabled registration's
// #defines.transformers, keyed by FQN. Verifies DEF-D3 (transformers ship
// through #defines) and 014 D7 (transformer presence is the registration).

_t04_platform: #Platform & {
	metadata: name: "transformers"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
		"k8up": {#module: _k8upModule}
	}
}

// 1 (deployment) + 1 (postgres) + 1 (backup-schedule) = 3
t04_transformerCount: len(_t04_platform.#composedTransformers) & 3

t04_deploymentKind: "ComponentTransformer" & _t04_platform.#composedTransformers["opmodel.dev/opm/v1alpha2/providers/kubernetes/deployment-transformer@v1"].kind
t04_pgKind:         "ComponentTransformer" & _t04_platform.#composedTransformers["vendor.com/postgres-operator/managed-database-transformer@v1"].kind
t04_backupKind:     "ModuleTransformer" & _t04_platform.#composedTransformers["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"].kind
