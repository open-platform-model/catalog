@if(test)

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
)

// #TestCtx constructs a minimal concrete #TransformerContext for transformer tests.
//
// The uuid is always the RFC 4122 nil UUID for deterministic, reproducible test output.
// The fqn is synthesised from the release name.
//
// Usage:
//
//	let _ctx = (#TestCtx & {
//	    release:   "my-release"
//	    namespace: "default"
//	    component: "web"
//	}).out
#TestCtx: {
	release!:   string
	namespace!: string
	component!: string

	out: transformer.#TransformerContext & {
		#moduleReleaseMetadata: {
			name:      release
			namespace: namespace
			fqn:       "opmodel.dev/opm/modules/\(release)@v0"
			version:   "v0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000001"
		}
		#componentMetadata: {
			name: component
		}
	}
}
