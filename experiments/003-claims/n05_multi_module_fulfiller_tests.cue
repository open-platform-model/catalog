@if(test_negative_multi_module_fulfiller)

package claims

// N05 — 014 D13 / CL-D17 boundary: two #ModuleTransformers fulfilling the
// same Claim FQN at platform level. Strict #Platform's
// _noMultiFulfiller constraint sums len(_invalid.{resources,traits,claims})
// and requires the sum to equal 0.
//
// Registering both _k8upModule and _alternateK8upModule produces two
// fulfillers for the BackupClaim FQN. _matchers._invalid.claims has 1
// entry; the constraint `0 & (... + 1)` = _|_ fails the strict platform.
//
// Run: `! cue vet -c -t test_negative_multi_module_fulfiller ./...`

_n05_platform: #Platform & {
	metadata: name: "n05"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {#module: _k8upModule}
		"alt-k8up": {#module: _alternateK8upModule}
	}
}

n05_force: _n05_platform.#matchers._noMultiFulfiller
