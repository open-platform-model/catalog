@if(test)

package platform_construct

// T07 — Multi-fulfiller diagnostic via #PlatformBase. Two registered
// transformers fulfill the same Claim FQN — _invalid populates with the
// offending FQN. The strict #Platform constraint would short-circuit to
// _|_ before we could inspect _invalid; #PlatformBase exposes the
// diagnostic surface.
//
// Anchors 014 D13 (multi-fulfiller forbidden — #matchers._invalid is the
// detection surface).

_t07_basePlatform: #PlatformBase & {
	metadata: name: "multi-fulfiller"
	type: "kubernetes"
	#registry: {
		"postgres": {#module: _postgresOperatorModule}
		"aiven-postgres": {#module: _aivenOperatorModule}
	}
}

// Both transformers' requiredClaims include managed-database@v1 → 1 invalid claim.
t07_invalidClaimsCount: 1 & len(_t07_basePlatform.#matchers._invalid.claims)
t07_invalidClaimFqn:    _t07_basePlatform.#matchers._invalid.claims[0] & "opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"

// Resources / traits unaffected.
t07_invalidResourcesEmpty: 0 & len(_t07_basePlatform.#matchers._invalid.resources)
t07_invalidTraitsEmpty:    0 & len(_t07_basePlatform.#matchers._invalid.traits)

// matchers.claims for the conflicted FQN holds both candidates.
t07_candidatesCount: 2 & len(_t07_basePlatform.#matchers.claims["opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"])
