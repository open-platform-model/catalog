@if(test)

package platform_construct

// T06 — #PlatformMatch.unmatched walker. THE bug-fix verification: the
// original 014/03-schema.md used `_demand.claims.module & _demand.claims.component`
// (struct unification — yields common keys only). The correct form unions
// the two keysets via a hidden `_claimDemand` map.

_t06_platform: #Platform & {
	metadata: name: "match-test"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"postgres": {#module: _postgresOperatorModule}
	}
}

// Consumer with one fulfilled Claim — db (managed-database, fulfilled by
// postgres operator).
_t06_match: #PlatformMatch & {
	platform: _t06_platform
	module:   _consumerWebApp
}

// matched.claims.db should resolve to one candidate.
t06_dbMatched: 1 & len(_t06_match.matched.claims["opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"])

// matched.resources.container should also resolve.
t06_containerMatched: 1 & len(_t06_match.matched.resources["opmodel.dev/opm/v1alpha2/resources/workload/container@v1"])

// Nothing unmatched in this scenario.
t06_unmatchedResourcesEmpty: 0 & len(_t06_match.unmatched.resources)
t06_unmatchedTraitsEmpty:    0 & len(_t06_match.unmatched.traits)
t06_unmatchedClaimsEmpty:    0 & len(_t06_match.unmatched.claims)

// Now a consumer with an UNFULFILLED Claim — proves the union walker
// correctly flags it (the buggy `&` form would miss it because it's
// component-level only, not at module level).
_t06b_match: #PlatformMatch & {
	platform: _t06_platform
	module:   _consumerUnfulfilled
}

// container is fulfilled (deployment-transformer); weird claim is not.
t06b_unmatchedResourcesEmpty: 0 & len(_t06b_match.unmatched.resources)
t06b_unmatchedClaimsCount:    1 & len(_t06b_match.unmatched.claims)
t06b_unmatchedClaimFqn:       _t06b_match.unmatched.claims[0] & "example.com/platform/v1alpha2/claims/unfulfilled@v1"
