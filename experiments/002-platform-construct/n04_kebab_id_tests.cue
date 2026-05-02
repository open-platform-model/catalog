@if(test_negative_kebab_id)

package platform_construct

// N04 — D16: #registry Id MUST be kebab-case (#NameType regex). Uppercase
// or underscores reject at definition time.
//
// Run: `! cue vet -c -t test_negative_kebab_id ./...`
// Expectation: cue vet FAILS with `field not allowed` on the offending Id.
// CUE folds the `#NameType` regex check into the pattern-constraint
// allowance test — non-kebab Ids report as field-not-allowed rather than
// as an explicit regex mismatch.

_n04_platform: #Platform & {
	metadata: name: "bad-id"
	type: "kubernetes"
	#registry: {
		// Underscore violates kebab regex.
		"opm_core": {#module: _opmCoreModule}
	}
}

n04_force: _n04_platform.#registry
