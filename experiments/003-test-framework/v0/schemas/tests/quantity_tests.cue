@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #NormalizeCPU
	// =========================================================================

	"#NormalizeCPU": [

		// ── Whole cores (number input) ──
		{name: "int 1", definition: #NormalizeCPU, input: {in: 1}, assert: output: out: "1"},
		{name: "int 2", definition: #NormalizeCPU, input: {in: 2}, assert: output: out: "2"},
		{name: "int 8", definition: #NormalizeCPU, input: {in: 8}, assert: output: out: "8"},
		{name: "int 16", definition: #NormalizeCPU, input: {in: 16}, assert: output: out: "16"},
		{name: "int 32", definition: #NormalizeCPU, input: {in: 32}, assert: output: out: "32"},
		{name: "int 64", definition: #NormalizeCPU, input: {in: 64}, assert: output: out: "64"},

		// ── Fractional cores (number input) ──
		{name: "float 0.5", definition: #NormalizeCPU, input: {in: 0.5}, assert: output: out: "500m"},
		{name: "float 0.25", definition: #NormalizeCPU, input: {in: 0.25}, assert: output: out: "250m"},
		{name: "float 1.5", definition: #NormalizeCPU, input: {in: 1.5}, assert: output: out: "1500m"},
		{name: "float 0.1", definition: #NormalizeCPU, input: {in: 0.1}, assert: output: out: "100m"},

		// ── Edge cases: zero and minimum ──
		{name: "zero", definition: #NormalizeCPU, input: {in: 0}, assert: output: out: "0"},
		{name: "float 0.001", definition: #NormalizeCPU, input: {in: 0.001}, assert: output: out: "1m"},

		// ── String passthrough (millicore format) ──
		{name: "string 500m", definition: #NormalizeCPU, input: {in: "500m"}, assert: output: out: "500m"},
		{name: "string 100m", definition: #NormalizeCPU, input: {in: "100m"}, assert: output: out: "100m"},
		{name: "string 1m", definition: #NormalizeCPU, input: {in: "1m"}, assert: output: out: "1m"},
		{name: "string 0m", definition: #NormalizeCPU, input: {in: "0m"}, assert: output: out: "0"},

		// ── String: whole-core millicore values ──
		{name: "string 1000m", definition: #NormalizeCPU, input: {in: "1000m"}, assert: output: out: "1"},
		{name: "string 2000m", definition: #NormalizeCPU, input: {in: "2000m"}, assert: output: out: "2"},
		{name: "string 4000m", definition: #NormalizeCPU, input: {in: "4000m"}, assert: output: out: "4"},
		{name: "string 8000m", definition: #NormalizeCPU, input: {in: "8000m"}, assert: output: out: "8"},
		{name: "string 64000m", definition: #NormalizeCPU, input: {in: "64000m"}, assert: output: out: "64"},
	]

	// =========================================================================
	// #NormalizeMemory
	// =========================================================================

	"#NormalizeMemory": [

		// ── Whole GiB (number input) ──
		{name: "int 1", definition: #NormalizeMemory, input: {in: 1}, assert: output: out: "1Gi"},
		{name: "int 4", definition: #NormalizeMemory, input: {in: 4}, assert: output: out: "4Gi"},
		{name: "int 16", definition: #NormalizeMemory, input: {in: 16}, assert: output: out: "16Gi"},
		{name: "int 32", definition: #NormalizeMemory, input: {in: 32}, assert: output: out: "32Gi"},
		{name: "int 64", definition: #NormalizeMemory, input: {in: 64}, assert: output: out: "64Gi"},
		{name: "int 128", definition: #NormalizeMemory, input: {in: 128}, assert: output: out: "128Gi"},

		// ── Fractional GiB (number input, converted to Mi) ──
		{name: "float 0.5", definition: #NormalizeMemory, input: {in: 0.5}, assert: output: out: "512Mi"},
		{name: "float 1.5", definition: #NormalizeMemory, input: {in: 1.5}, assert: output: out: "1536Mi"},
		{name: "float 0.25", definition: #NormalizeMemory, input: {in: 0.25}, assert: output: out: "256Mi"},
		{name: "float 0.125", definition: #NormalizeMemory, input: {in: 0.125}, assert: output: out: "128Mi"},
		{name: "float 0.0625", definition: #NormalizeMemory, input: {in: 0.0625}, assert: output: out: "64Mi"},
		{name: "float 0.001953125", definition: #NormalizeMemory, input: {in: 0.001953125}, assert: output: out: "2Mi"},

		// ── Edge cases: zero ──
		{name: "zero", definition: #NormalizeMemory, input: {in: 0}, assert: output: out: "0Gi"},

		// ── String passthrough (Mi/Gi format) ──
		{name: "string 256Mi", definition: #NormalizeMemory, input: {in: "256Mi"}, assert: output: out: "256Mi"},
		{name: "string 1024Mi", definition: #NormalizeMemory, input: {in: "1024Mi"}, assert: output: out: "1024Mi"},
		{name: "string 32768Mi", definition: #NormalizeMemory, input: {in: "32768Mi"}, assert: output: out: "32768Mi"},
		{name: "string 4Gi", definition: #NormalizeMemory, input: {in: "4Gi"}, assert: output: out: "4Gi"},
		{name: "string 8Gi", definition: #NormalizeMemory, input: {in: "8Gi"}, assert: output: out: "8Gi"},
		{name: "string 128Gi", definition: #NormalizeMemory, input: {in: "128Gi"}, assert: output: out: "128Gi"},
		{name: "string 0Mi", definition: #NormalizeMemory, input: {in: "0Mi"}, assert: output: out: "0Mi"},
		{name: "string 1Mi", definition: #NormalizeMemory, input: {in: "1Mi"}, assert: output: out: "1Mi"},
		{name: "string 0Gi", definition: #NormalizeMemory, input: {in: "0Gi"}, assert: output: out: "0Gi"},
	]

	// =========================================================================
	// #ResourceRequirementsSchema
	// =========================================================================

	"#ResourceRequirementsSchema": [

		// ── Valid: string formats ──
		{
			name:       "full string specification"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: {request: "100m", limit: "500m"}
				memory: {request: "128Mi", limit: "512Mi"}
			}
			assert: valid: true
		},
		{
			name:       "partial: request only"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: request:    "500m"
				memory: request: "256Mi"
			}
			assert: valid: true
		},
		{
			name:       "cpu only"
			definition: #ResourceRequirementsSchema
			input: cpu: {request: "500m", limit: "2000m"}
			assert: valid: true
		},
		{
			name:       "memory only"
			definition: #ResourceRequirementsSchema
			input: memory: {request: "256Mi", limit: "1Gi"}
			assert: valid: true
		},
		{
			name:       "limit only"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: limit:    "1000m"
				memory: limit: "512Mi"
			}
			assert: valid: true
		},
		{
			name:       "empty"
			definition: #ResourceRequirementsSchema
			input: {}
			assert: valid: true
		},

		// ── Valid: numeric values ──
		{
			name:       "numeric values"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: {request: 0.5, limit: 2}
				memory: {request: 0.5, limit: 4}
			}
			assert: valid: true
		},
		{
			name:       "mixed types"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: {request: 2, limit: "8000m"}
				memory: {request: "512Mi", limit: 4}
			}
			assert: valid: true
		},
		{
			name:       "large values"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: {request: 16, limit: 64}
				memory: {request: 32, limit: 128}
			}
			assert: valid: true
		},
		{
			name:       "small fractions"
			definition: #ResourceRequirementsSchema
			input: {
				cpu: {request: 0.1, limit: 0.5}
				memory: {request: 0.125, limit: 0.25}
			}
			assert: valid: true
		},

		// ── Invalid: bad formats ──
		{
			name:       "bad CPU format (non-millicore string)"
			definition: #ResourceRequirementsSchema
			input: cpu: {request: "2cores", limit: "500m"}
			assert: valid: false
		},
		{
			name:       "bad CPU string (no m suffix)"
			definition: #ResourceRequirementsSchema
			input: cpu: {request: "500", limit: "1000m"}
			assert: valid: false
		},
		{
			name:       "bad memory format (GB suffix)"
			definition: #ResourceRequirementsSchema
			input: memory: {request: "256Mi", limit: "4GB"}
			assert: valid: false
		},
		{
			name:       "bad memory string (kb suffix)"
			definition: #ResourceRequirementsSchema
			input: memory: {request: "256kb", limit: "512Mi"}
			assert: valid: false
		},
		{
			name:       "bad memory string (Ti suffix)"
			definition: #ResourceRequirementsSchema
			input: memory: {request: "256Mi", limit: "1Ti"}
			assert: valid: false
		},
	]
}
