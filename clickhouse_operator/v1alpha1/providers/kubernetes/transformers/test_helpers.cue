@if(test)

package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
)

// #TestCtx constructs a minimal concrete #TransformerContext for transformer tests.
#TestCtx: {
	release!:   string
	namespace!: string
	component!: string

	out: transformer.#TransformerContext & {
		#moduleReleaseMetadata: {
			name:      release
			namespace: namespace
			fqn:       "opmodel.dev/clickhouse_operator/v1alpha1/modules/\(release)@v0"
			version:   "v0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000001"
		}
		#componentMetadata: {
			name: component
		}
	}
}
