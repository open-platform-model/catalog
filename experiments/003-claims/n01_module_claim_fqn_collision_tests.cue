@if(test_negative_module_claim_collision)

package claims

// N01 — CL-D18 module-level Claim FQN uniqueness.
// Two #claims entries on a module sharing the same metadata.fqn must
// surface as _|_ via the hidden _noDuplicateModuleClaimFqn constraint.
//
// Run: `! cue vet -c -t test_negative_module_claim_collision ./...`

_n01_collision: #Module & {
	metadata: {
		modulePath: "example.com/test"
		name:       "collision"
		version:    "0.1.0"
		fqn:        "example.com/test/collision:0.1.0"
		uuid:       "00000000-0000-0000-0000-0000000000c1"
	}
	#claims: {
		first: _backupClaim & {#spec: {schedule: "0 1 * * *", backend: "a"}}
		// Second claim under different id, same FQN — CL-D18 violation.
		second: _backupClaim & {#spec: {schedule: "0 2 * * *", backend: "b"}}
	}
}

// Force evaluation of the duplicate-FQN constraint.
n01_collide: _n01_collision._noDuplicateModuleClaimFqn
