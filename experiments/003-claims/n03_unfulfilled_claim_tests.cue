@if(test_negative_unfulfilled_claim)

package claims

// N03 — Validation phase contract: a consumer Claim with no registered
// fulfiller transformer must surface in #PlatformMatch.unmatched.claims.
//
// _consumerUnfulfilled has a component-level Claim whose FQN matches no
// transformer's requiredClaims. The platform demand walker reports it.
// The test forces a 0-element constraint against a non-empty list to
// guarantee CUE vet fails with a count conflict.
//
// Run: `! cue vet -c -t test_negative_unfulfilled_claim ./...`

_n03_platform: #PlatformBase & {
	metadata: name: "n03"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		// _consumerUnfulfilled's claim FQN
		// "example.com/platform/v1alpha2/claims/unfulfilled@v1" has no
		// transformer in any registered module.
	}
}

_n03_match: #PlatformMatch & {
	platform: _n03_platform
	module:   _consumerUnfulfilled
}

// Pretend there are zero unmatched claims; reality says 1.
// 0 & 1 ⇒ _|_ ⇒ vet fails.
n03_force: 0 & len(_n03_match.unmatched.claims)
