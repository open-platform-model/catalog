@if(test)

package platform_construct

// T08 — `enabled: false` hides every projection of an entry. Anchors 014 D14.
//
// Two registrations: opm-core (enabled), k8up (disabled). Expectations:
// - #knownResources only carries opm-core's resources (container, volume).
// - #knownTraits skips k8up's backup-trait — only opm-core's expose visible.
// - #knownClaims skips k8up's backup-claim — only opm-core's managed-database.
// - #composedTransformers skips k8up's backup-schedule-transformer.

_t08_platform: #Platform & {
	metadata: name: "enabled-test"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {
			#module: _k8upModule
			enabled: false
		}
	}
}

t08_knownResourcesCount: 2 & len(_t08_platform.#knownResources)       // container + volume
t08_knownTraitsCount:    1 & len(_t08_platform.#knownTraits)          // expose only
t08_knownClaimsCount:    1 & len(_t08_platform.#knownClaims)          // managed-database only
t08_transformersCount:   2 & len(_t08_platform.#composedTransformers) // deployment + service

// Specifically the disabled module's primitives are absent.
t08_backupTraitAbsent:       _t08_platform.#knownTraits["opmodel.dev/opm/v1alpha2/operations/backup/backup-trait@v1"] == _|_ & true
t08_backupClaimAbsent:       _t08_platform.#knownClaims["opmodel.dev/opm/v1alpha2/operations/backup/backup-claim@v1"] == _|_ & true
t08_backupTransformerAbsent: _t08_platform.#composedTransformers["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"] == _|_ & true
