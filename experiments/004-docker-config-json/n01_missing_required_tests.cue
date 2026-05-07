@if(test_negative_missing_registry)

package dockerconfigjson

// N01 — required field enforcement.
// #DockerConfigJSON declares registry, username, password as required (`!`).
// Omitting any of them must surface as an incomplete value when evaluated
// concretely.
//
// Run: `! cue vet -c -t test_negative_missing_registry ./...`

_n01_missingRegistry: #DockerConfigJSON & {
	username: "alice"
	password: "s3cret"
}

// Force concreteness check on the missing-registry case.
n01_missingRegistry: _n01_missingRegistry.out
