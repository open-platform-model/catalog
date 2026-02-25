@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #NormalizeCPU
	// =========================================================================

	normalizeCPU: [

		// ── Whole cores (number input) ──
		{name: "int 1", definition: "#NormalizeCPU", input: {in: 1}, assert: fields: out: equals: "1"},
		{name: "int 2", definition: "#NormalizeCPU", input: {in: 2}, assert: fields: out: equals: "2"},
		{name: "int 8", definition: "#NormalizeCPU", input: {in: 8}, assert: fields: out: equals: "8"},
		{name: "int 16", definition: "#NormalizeCPU", input: {in: 16}, assert: fields: out: equals: "16"},
		{name: "int 32", definition: "#NormalizeCPU", input: {in: 32}, assert: fields: out: equals: "32"},
		{name: "int 64", definition: "#NormalizeCPU", input: {in: 64}, assert: fields: out: equals: "64"},

		// ── Fractional cores (number input) ──
		{name: "float 0.5", definition: "#NormalizeCPU", input: {in: 0.5}, assert: fields: out: equals: "500m"},
		{name: "float 0.25", definition: "#NormalizeCPU", input: {in: 0.25}, assert: fields: out: equals: "250m"},
		{name: "float 1.5", definition: "#NormalizeCPU", input: {in: 1.5}, assert: fields: out: equals: "1500m"},
		{name: "float 0.1", definition: "#NormalizeCPU", input: {in: 0.1}, assert: fields: out: equals: "100m"},

		// ── Edge cases: zero and minimum ──
		{name: "zero", definition: "#NormalizeCPU", input: {in: 0}, assert: fields: out: equals: "0"},
		{name: "float 0.001", definition: "#NormalizeCPU", input: {in: 0.001}, assert: fields: out: equals: "1m"},

		// ── String passthrough (millicore format) ──
		{name: "string 500m", definition: "#NormalizeCPU", input: {in: "500m"}, assert: fields: out: equals: "500m"},
		{name: "string 100m", definition: "#NormalizeCPU", input: {in: "100m"}, assert: fields: out: equals: "100m"},
		{name: "string 1m", definition: "#NormalizeCPU", input: {in: "1m"}, assert: fields: out: equals: "1m"},
		{name: "string 0m", definition: "#NormalizeCPU", input: {in: "0m"}, assert: fields: out: equals: "0"},

		// ── String: whole-core millicore values ──
		{name: "string 1000m", definition: "#NormalizeCPU", input: {in: "1000m"}, assert: fields: out: equals: "1"},
		{name: "string 2000m", definition: "#NormalizeCPU", input: {in: "2000m"}, assert: fields: out: equals: "2"},
		{name: "string 4000m", definition: "#NormalizeCPU", input: {in: "4000m"}, assert: fields: out: equals: "4"},
		{name: "string 8000m", definition: "#NormalizeCPU", input: {in: "8000m"}, assert: fields: out: equals: "8"},
		{name: "string 64000m", definition: "#NormalizeCPU", input: {in: "64000m"}, assert: fields: out: equals: "64"},
	]

	// =========================================================================
	// #NormalizeMemory
	// =========================================================================

	normalizeMemory: [

		// ── Whole GiB (number input) ──
		{name: "int 1", definition: "#NormalizeMemory", input: {in: 1}, assert: fields: out: equals: "1Gi"},
		{name: "int 4", definition: "#NormalizeMemory", input: {in: 4}, assert: fields: out: equals: "4Gi"},
		{name: "int 16", definition: "#NormalizeMemory", input: {in: 16}, assert: fields: out: equals: "16Gi"},
		{name: "int 32", definition: "#NormalizeMemory", input: {in: 32}, assert: fields: out: equals: "32Gi"},
		{name: "int 64", definition: "#NormalizeMemory", input: {in: 64}, assert: fields: out: equals: "64Gi"},
		{name: "int 128", definition: "#NormalizeMemory", input: {in: 128}, assert: fields: out: equals: "128Gi"},

		// ── Fractional GiB (number input, converted to Mi) ──
		{name: "float 0.5", definition: "#NormalizeMemory", input: {in: 0.5}, assert: fields: out: equals: "512Mi"},
		{name: "float 1.5", definition: "#NormalizeMemory", input: {in: 1.5}, assert: fields: out: equals: "1536Mi"},
		{name: "float 0.25", definition: "#NormalizeMemory", input: {in: 0.25}, assert: fields: out: equals: "256Mi"},
		{name: "float 0.125", definition: "#NormalizeMemory", input: {in: 0.125}, assert: fields: out: equals: "128Mi"},
		{name: "float 0.0625", definition: "#NormalizeMemory", input: {in: 0.0625}, assert: fields: out: equals: "64Mi"},
		{name: "float 0.001953125", definition: "#NormalizeMemory", input: {in: 0.001953125}, assert: fields: out: equals: "2Mi"},

		// ── Edge cases: zero ──
		{name: "zero", definition: "#NormalizeMemory", input: {in: 0}, assert: fields: out: equals: "0Gi"},

		// ── String passthrough (Mi/Gi format) ──
		{name: "string 256Mi", definition: "#NormalizeMemory", input: {in: "256Mi"}, assert: fields: out: equals: "256Mi"},
		{name: "string 1024Mi", definition: "#NormalizeMemory", input: {in: "1024Mi"}, assert: fields: out: equals: "1024Mi"},
		{name: "string 32768Mi", definition: "#NormalizeMemory", input: {in: "32768Mi"}, assert: fields: out: equals: "32768Mi"},
		{name: "string 4Gi", definition: "#NormalizeMemory", input: {in: "4Gi"}, assert: fields: out: equals: "4Gi"},
		{name: "string 8Gi", definition: "#NormalizeMemory", input: {in: "8Gi"}, assert: fields: out: equals: "8Gi"},
		{name: "string 128Gi", definition: "#NormalizeMemory", input: {in: "128Gi"}, assert: fields: out: equals: "128Gi"},
		{name: "string 0Mi", definition: "#NormalizeMemory", input: {in: "0Mi"}, assert: fields: out: equals: "0Mi"},
		{name: "string 1Mi", definition: "#NormalizeMemory", input: {in: "1Mi"}, assert: fields: out: equals: "1Mi"},
		{name: "string 0Gi", definition: "#NormalizeMemory", input: {in: "0Gi"}, assert: fields: out: equals: "0Gi"},
	]

	// =========================================================================
	// #ResourceRequirementsSchema
	// =========================================================================

	resourceRequirements: [

		// ── Positive: valid inputs ──
		{
			name:       "full string specification"
			definition: "#ResourceRequirementsSchema"
			input: {
				cpu: {request: "100m", limit: "500m"}
				memory: {request: "128Mi", limit: "512Mi"}
			}
			assert: valid: true
		},
		{
			name:       "numeric values"
			definition: "#ResourceRequirementsSchema"
			input: {
				cpu: {request: 0.5, limit: 2}
				memory: {request: 0.5, limit: 4}
			}
			assert: valid: true
		},
		{
			name:       "partial: request only"
			definition: "#ResourceRequirementsSchema"
			input: {
				cpu: request:    "500m"
				memory: request: "256Mi"
			}
			assert: valid: true
		},
		{
			name:       "cpu only"
			definition: "#ResourceRequirementsSchema"
			input: cpu: {request: "500m", limit: "2000m"}
			assert: valid: true
		},
		{
			name:       "mixed types"
			definition: "#ResourceRequirementsSchema"
			input: {
				cpu: {request: 2, limit: "8000m"}
				memory: {request: "512Mi", limit: 4}
			}
			assert: valid: true
		},
		{
			name:       "limit only"
			definition: "#ResourceRequirementsSchema"
			input: {
				cpu: limit:    "1000m"
				memory: limit: "512Mi"
			}
			assert: valid: true
		},

		// ── Negative: invalid inputs ──
		{
			name:       "bad CPU format (non-millicore string)"
			definition: "#ResourceRequirementsSchema"
			input: cpu: {request: "2cores", limit: "500m"}
			assert: valid: false
		},
		{
			name:       "bad CPU string (no m suffix)"
			definition: "#ResourceRequirementsSchema"
			input: cpu: {request: "500", limit: "1000m"}
			assert: valid: false
		},
		{
			name:       "bad memory format (GB suffix)"
			definition: "#ResourceRequirementsSchema"
			input: memory: {request: "256Mi", limit: "4GB"}
			assert: valid: false
		},
		{
			name:       "bad memory string (kb suffix)"
			definition: "#ResourceRequirementsSchema"
			input: memory: {request: "256kb", limit: "512Mi"}
			assert: valid: false
		},
		{
			name:       "bad memory string (Ti suffix)"
			definition: "#ResourceRequirementsSchema"
			input: memory: {request: "256Mi", limit: "1Ti"}
			assert: valid: false
		},
	]
}
