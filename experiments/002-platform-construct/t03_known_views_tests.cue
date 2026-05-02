@if(test)

package platform_construct

// T03 — #knownResources / #knownTraits / #knownClaims projections aggregate
// every enabled registration's #defines.{resources,traits,claims}.

_t03_platform: #Platform & {
	metadata: name: "known-views"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {#module: _k8upModule}
	}
}

// OPM core ships container + volume → 2 resource types.
t03_knownResourcesCount: len(_t03_platform.#knownResources) & 2

// OPM core ships expose; k8up ships backup-trait → 2.
t03_knownTraitsCount: len(_t03_platform.#knownTraits) & 2

// OPM core ships managed-database; k8up ships backup-claim → 2.
t03_knownClaimsCount: len(_t03_platform.#knownClaims) & 2

// Verify FQN-keyed access works.
t03_knownContainerByFqn:   _t03_platform.#knownResources["opmodel.dev/opm/v1alpha2/resources/workload/container@v1"].metadata.name & "container"
t03_knownBackupTraitByFqn: _t03_platform.#knownTraits["opmodel.dev/opm/v1alpha2/operations/backup/backup-trait@v1"].metadata.name & "backup-trait"
t03_knownDbClaimByFqn:     _t03_platform.#knownClaims["opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"].metadata.name & "managed-database"
