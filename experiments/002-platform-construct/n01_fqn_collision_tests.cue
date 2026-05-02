@if(test_negative_fqn_collision)

package platform_construct

// N01 — D3 FQN collision: two registered Modules ship #defines.resources
// with the same FQN but conflicting values. CUE unification on
// #knownResources must fail.
//
// Run: `! cue vet -c -t test_negative_fqn_collision ./...`
// Expectation: cue vet FAILS with "conflicting values" or similar.

_n01_modA: #Module & {
	metadata: {
		modulePath: "example.com/a"
		name:       "mod-a"
		version:    "0.1.0"
		fqn:        "example.com/a/mod-a:0.1.0"
		uuid:       "00000000-0000-0000-0000-0000000000a1"
	}
	#defines: resources: {
		"example.com/types/widget@v1": {
			apiVersion: "opmodel.dev/core/v1alpha2"
			metadata: {
				modulePath:  "example.com/types"
				name:        "widget"
				version:     "v1"
				fqn:         "example.com/types/widget@v1"
				description: "Widget shipped by Mod A"
			}
		}
	}
}

_n01_modB: #Module & {
	metadata: {
		modulePath: "example.com/b"
		name:       "mod-b"
		version:    "0.1.0"
		fqn:        "example.com/b/mod-b:0.1.0"
		uuid:       "00000000-0000-0000-0000-0000000000b1"
	}
	#defines: resources: {
		"example.com/types/widget@v1": {
			apiVersion: "opmodel.dev/core/v1alpha2"
			metadata: {
				modulePath:  "example.com/types"
				name:        "widget"
				version:     "v1"
				fqn:         "example.com/types/widget@v1"
				description: "Widget shipped by Mod B (different copy)"
			}
		}
	}
}

_n01_platform: #Platform & {
	metadata: name: "fqn-collision"
	type: "kubernetes"
	#registry: {
		"mod-a": {#module: _n01_modA}
		"mod-b": {#module: _n01_modB}
	}
}

// Forces evaluation of #knownResources. Should fail with conflict on
// "example.com/types/widget@v1".
n01_collide: _n01_platform.#knownResources
