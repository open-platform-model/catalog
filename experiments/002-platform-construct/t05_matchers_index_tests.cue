@if(test)

package platform_construct

// T05 — #matchers reverse index maps demanded FQN → candidate transformers.
// Verifies 014 D12 (matcher logic on #Platform).

_t05_platform: #Platform & {
	metadata: name: "matchers"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
		"k8up": {#module: _k8upModule}
	}
}

// Container resource has one fulfiller (deployment-transformer).
t05_containerCandidateCount: 1 & len(_t05_platform.#matchers.resources["opmodel.dev/opm/v1alpha2/resources/workload/container@v1"])

// Managed-database claim has one fulfiller (postgres operator).
t05_dbClaimCandidateCount: 1 & len(_t05_platform.#matchers.claims["opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"])

// Backup claim has one fulfiller (k8up).
t05_backupClaimCandidateCount: 1 & len(_t05_platform.#matchers.claims["opmodel.dev/opm/v1alpha2/operations/backup/backup-claim@v1"])

// Volume resource has zero fulfillers — no transformer demands it.
// (Looking it up returns _|_ via the index since fqn never lands.)
t05_volumeUnindexed: _t05_platform.#matchers.resources["opmodel.dev/opm/v1alpha2/resources/storage/volume@v1"] == _|_ & true

// Single-fulfiller setup → no _invalid entries.
t05_invalidEmpty: 0 & (len(_t05_platform.#matchers._invalid.resources) +
	len(_t05_platform.#matchers._invalid.traits) +
	len(_t05_platform.#matchers._invalid.claims))
