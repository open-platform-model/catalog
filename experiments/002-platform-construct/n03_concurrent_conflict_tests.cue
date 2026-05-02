@if(test_negative_concurrent_conflict)

package platform_construct

// N03 — D15: static + runtime writes to the same #registry[Id] with
// concrete-value disagreement produce _|_. opm-operator catches and
// surfaces in ModuleRelease.status.conditions.
//
// Run: `! cue vet -c -t test_negative_concurrent_conflict ./...`
// Expectation: cue vet FAILS with `conflicting values "0.5.0" and "0.6.0"`.
// Error label points at the forcing test field (n03_force); trace lines
// point at the two `_n03_modV*` declarations where the values disagree.

// Two Module values for the same registration Id, differing on version.
_n03_modV1: #Module & {
	metadata: {
		modulePath: "vendor.com/operators"
		name:       "postgres"
		version:    "0.5.0"
		fqn:        "vendor.com/operators/postgres:0.5.0"
		uuid:       "00000000-0000-0000-0000-0000000000c1"
	}
}

_n03_modV2: #Module & {
	metadata: {
		modulePath: "vendor.com/operators"
		name:       "postgres"
		version:    "0.6.0"
		fqn:        "vendor.com/operators/postgres:0.6.0"
		uuid:       "00000000-0000-0000-0000-0000000000c2"
	}
}

_n03_static: #Platform & {
	metadata: name: "conflict"
	type: "kubernetes"
	#registry: {
		"postgres": {#module: _n03_modV1}
	}
}

_n03_runtime: #Platform & {
	metadata: name: "conflict"
	type: "kubernetes"
	#registry: {
		"postgres": {#module: _n03_modV2}
	}
}

n03_force: (_n03_static & _n03_runtime).#registry."postgres".#module.metadata.version
