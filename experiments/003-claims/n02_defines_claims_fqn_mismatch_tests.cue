@if(test_negative_defines_fqn_mismatch)

package claims

// N02 — DEF-D2 #defines.claims FQN-binding.
// Map key is bound to value.metadata.fqn via `[FQN=string]: #Claim &
// {metadata: fqn: FQN}`. A typo in the key OR mismatched value FQN must
// cause unification failure at definition time.
//
// Run: `! cue vet -c -t test_negative_defines_fqn_mismatch ./...`

_n02_module: #Module & {
	metadata: {
		modulePath: "example.com/test"
		name:       "fqn-mismatch"
		version:    "0.1.0"
		fqn:        "example.com/test/fqn-mismatch:0.1.0"
		uuid:       "00000000-0000-0000-0000-0000000000c2"
	}
	#defines: claims: {
		// Map key has a typo — the value's metadata.fqn computes to
		// "opmodel.dev/opm/v1alpha2/operations/backup/backup-claim@v1".
		// Unification of "...wrong-fqn@v1" & "...backup-claim@v1" fails.
		"opmodel.dev/opm/v1alpha2/operations/backup/wrong-fqn@v1": _backupClaim
	}
}

n02_force: _n02_module.#defines.claims
