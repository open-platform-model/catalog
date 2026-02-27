@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

// ── NormalizeCPU test data: {in, out} pairs ──
_cpuCases: [
	// Whole cores (number input)
	{in: 1,  out: "1"},
	{in: 2,  out: "2"},
	{in: 8,  out: "8"},
	{in: 16, out: "16"},
	{in: 32, out: "32"},
	{in: 64, out: "64"},

	// Fractional cores (number input → millicore output)
	{in: 0.5,   out: "500m"},
	{in: 0.25,  out: "250m"},
	{in: 1.5,   out: "1500m"},
	{in: 0.1,   out: "100m"},

	// Edge cases
	{in: 0,     out: "0"},
	{in: 0.001, out: "1m"},

	// String passthrough (millicore format)
	{in: "500m", out: "500m"},
	{in: "100m", out: "100m"},
	{in: "1m",   out: "1m"},
	{in: "0m",   out: "0"},

	// String: whole-core millicore values that normalize to cores
	{in: "1000m",  out: "1"},
	{in: "2000m",  out: "2"},
	{in: "4000m",  out: "4"},
	{in: "8000m",  out: "8"},
	{in: "64000m", out: "64"},
]

// ── NormalizeMemory test data: {in, out} pairs ──
_memoryCases: [
	// Whole GiB (number input)
	{in: 1,   out: "1Gi"},
	{in: 4,   out: "4Gi"},
	{in: 16,  out: "16Gi"},
	{in: 32,  out: "32Gi"},
	{in: 64,  out: "64Gi"},
	{in: 128, out: "128Gi"},

	// Fractional GiB (number input → Mi output)
	{in: 0.5,         out: "512Mi"},
	{in: 1.5,         out: "1536Mi"},
	{in: 0.25,        out: "256Mi"},
	{in: 0.125,       out: "128Mi"},
	{in: 0.0625,      out: "64Mi"},
	{in: 0.001953125, out: "2Mi"},

	// Edge case: zero
	{in: 0, out: "0Gi"},

	// String passthrough (Mi/Gi format)
	{in: "256Mi",   out: "256Mi"},
	{in: "1024Mi",  out: "1024Mi"},
	{in: "32768Mi", out: "32768Mi"},
	{in: "4Gi",     out: "4Gi"},
	{in: "8Gi",     out: "8Gi"},
	{in: "128Gi",   out: "128Gi"},
	{in: "0Mi",     out: "0Mi"},
	{in: "1Mi",     out: "1Mi"},
	{in: "0Gi",     out: "0Gi"},
]

#tests: tst.#Tests & {

	// =========================================================================
	// #NormalizeCPU
	// =========================================================================

	"#NormalizeCPU": [
		for c in _cpuCases {
			name:       "cpu \(c.in) -> \(c.out)"
			definition: #NormalizeCPU
			input: in:  c.in
			assert: output: out: c.out
		},
	]

	// =========================================================================
	// #NormalizeMemory
	// =========================================================================

	"#NormalizeMemory": [
		for c in _memoryCases {
			name:       "mem \(c.in) -> \(c.out)"
			definition: #NormalizeMemory
			input: in:  c.in
			assert: output: out: c.out
		},
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
