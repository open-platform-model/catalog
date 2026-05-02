@if(test_negative_multi_fulfiller)

package platform_construct

// N02 — D13: strict #Platform refuses to evaluate when two transformers
// fulfill the same Claim FQN. The hidden _noMultiFulfiller constraint
// unifies len(_invalid.*) sum with concrete 0 and falls to _|_ when > 0.
//
// Run: `! cue vet -c -t test_negative_multi_fulfiller ./...`
// Expectation: cue vet FAILS with "conflicting values 0 and 1" (or similar
// non-zero) on _noMultiFulfiller.

_n02_platform: #Platform & {
	metadata: name: "two-fulfillers"
	type: "kubernetes"
	#registry: {
		"postgres": {#module: _postgresOperatorModule}
		"aiven-postgres": {#module: _aivenOperatorModule}
	}
}

n02_force: _n02_platform.#matchers._noMultiFulfiller
