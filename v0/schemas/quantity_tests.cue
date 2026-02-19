@if(test)

package schemas

// =============================================================================
// Quantity Normalization Tests
// =============================================================================

// ── #NormalizeCPU ────────────────────────────────────────────────

// Whole cores as integers
_testNormalizeCPU_Int1: (#NormalizeCPU & {in: 1}).out
_testNormalizeCPU_Int1: "1"

_testNormalizeCPU_Int2: (#NormalizeCPU & {in: 2}).out
_testNormalizeCPU_Int2: "2"

_testNormalizeCPU_Int8: (#NormalizeCPU & {in: 8}).out
_testNormalizeCPU_Int8: "8"

// Fractional cores as floats
_testNormalizeCPU_Float05: (#NormalizeCPU & {in: 0.5}).out
_testNormalizeCPU_Float05: "500m"

_testNormalizeCPU_Float025: (#NormalizeCPU & {in: 0.25}).out
_testNormalizeCPU_Float025: "250m"

_testNormalizeCPU_Float15: (#NormalizeCPU & {in: 1.5}).out
_testNormalizeCPU_Float15: "1500m"

_testNormalizeCPU_Float01: (#NormalizeCPU & {in: 0.1}).out
_testNormalizeCPU_Float01: "100m"

// String passthrough (millicore format)
_testNormalizeCPU_String500m: (#NormalizeCPU & {in: "500m"}).out
_testNormalizeCPU_String500m: "500m"

_testNormalizeCPU_String2000m: (#NormalizeCPU & {in: "2000m"}).out
_testNormalizeCPU_String2000m: "2"

_testNormalizeCPU_String100m: (#NormalizeCPU & {in: "100m"}).out
_testNormalizeCPU_String100m: "100m"

// Edge cases: zero and minimum
_testNormalizeCPU_Zero: (#NormalizeCPU & {in: 0}).out
_testNormalizeCPU_Zero: "0"

_testNormalizeCPU_Float001: (#NormalizeCPU & {in: 0.001}).out
_testNormalizeCPU_Float001: "1m"

_testNormalizeCPU_String1m: (#NormalizeCPU & {in: "1m"}).out
_testNormalizeCPU_String1m: "1m"

_testNormalizeCPU_String0m: (#NormalizeCPU & {in: "0m"}).out
_testNormalizeCPU_String0m: "0"

// Edge cases: large values
_testNormalizeCPU_Int16: (#NormalizeCPU & {in: 16}).out
_testNormalizeCPU_Int16: "16"

_testNormalizeCPU_Int32: (#NormalizeCPU & {in: 32}).out
_testNormalizeCPU_Int32: "32"

_testNormalizeCPU_Int64: (#NormalizeCPU & {in: 64}).out
_testNormalizeCPU_Int64: "64"

_testNormalizeCPU_String64000m: (#NormalizeCPU & {in: "64000m"}).out
_testNormalizeCPU_String64000m: "64"

// Whole-core string inputs
_testNormalizeCPU_String1000m: (#NormalizeCPU & {in: "1000m"}).out
_testNormalizeCPU_String1000m: "1"

_testNormalizeCPU_String4000m: (#NormalizeCPU & {in: "4000m"}).out
_testNormalizeCPU_String4000m: "4"

_testNormalizeCPU_String8000m: (#NormalizeCPU & {in: "8000m"}).out
_testNormalizeCPU_String8000m: "8"

// ── #NormalizeMemory ─────────────────────────────────────────────

// Whole GiB as integers (should use Gi suffix)
_testNormalizeMemory_Int1: (#NormalizeMemory & {in: 1}).out
_testNormalizeMemory_Int1: "1Gi"

_testNormalizeMemory_Int4: (#NormalizeMemory & {in: 4}).out
_testNormalizeMemory_Int4: "4Gi"

_testNormalizeMemory_Int16: (#NormalizeMemory & {in: 16}).out
_testNormalizeMemory_Int16: "16Gi"

// Fractional GiB as floats (should convert to Mi)
_testNormalizeMemory_Float05: (#NormalizeMemory & {in: 0.5}).out
_testNormalizeMemory_Float05: "512Mi"

_testNormalizeMemory_Float15: (#NormalizeMemory & {in: 1.5}).out
_testNormalizeMemory_Float15: "1536Mi"

_testNormalizeMemory_Float025: (#NormalizeMemory & {in: 0.25}).out
_testNormalizeMemory_Float025: "256Mi"

_testNormalizeMemory_Float0125: (#NormalizeMemory & {in: 0.125}).out
_testNormalizeMemory_Float0125: "128Mi"

// String passthrough (Mi/Gi format)
_testNormalizeMemory_String256Mi: (#NormalizeMemory & {in: "256Mi"}).out
_testNormalizeMemory_String256Mi: "256Mi"

_testNormalizeMemory_String4Gi: (#NormalizeMemory & {in: "4Gi"}).out
_testNormalizeMemory_String4Gi: "4Gi"

_testNormalizeMemory_String1024Mi: (#NormalizeMemory & {in: "1024Mi"}).out
_testNormalizeMemory_String1024Mi: "1024Mi"

_testNormalizeMemory_String8Gi: (#NormalizeMemory & {in: "8Gi"}).out
_testNormalizeMemory_String8Gi: "8Gi"

// Edge cases: zero and minimum
_testNormalizeMemory_Zero: (#NormalizeMemory & {in: 0}).out
_testNormalizeMemory_Zero: "0Gi"

_testNormalizeMemory_String0Mi: (#NormalizeMemory & {in: "0Mi"}).out
_testNormalizeMemory_String0Mi: "0Mi"

_testNormalizeMemory_String1Mi: (#NormalizeMemory & {in: "1Mi"}).out
_testNormalizeMemory_String1Mi: "1Mi"

_testNormalizeMemory_String0Gi: (#NormalizeMemory & {in: "0Gi"}).out
_testNormalizeMemory_String0Gi: "0Gi"

// Edge cases: small fractions (binary-exact)
_testNormalizeMemory_Float0625: (#NormalizeMemory & {in: 0.0625}).out
_testNormalizeMemory_Float0625: "64Mi"

_testNormalizeMemory_Float001953125: (#NormalizeMemory & {in: 0.001953125}).out
_testNormalizeMemory_Float001953125: "2Mi"

// Edge cases: large values
_testNormalizeMemory_Int32: (#NormalizeMemory & {in: 32}).out
_testNormalizeMemory_Int32: "32Gi"

_testNormalizeMemory_Int64: (#NormalizeMemory & {in: 64}).out
_testNormalizeMemory_Int64: "64Gi"

_testNormalizeMemory_Int128: (#NormalizeMemory & {in: 128}).out
_testNormalizeMemory_Int128: "128Gi"

_testNormalizeMemory_String32768Mi: (#NormalizeMemory & {in: "32768Mi"}).out
_testNormalizeMemory_String32768Mi: "32768Mi"

_testNormalizeMemory_String128Gi: (#NormalizeMemory & {in: "128Gi"}).out
_testNormalizeMemory_String128Gi: "128Gi"

// =============================================================================
// #ResourceRequirementsSchema Validation Tests
//
// Verifies that #ResourceRequirementsSchema accepts valid inputs.
// Normalization is tested via #NormalizeCPU / #NormalizeMemory above.
// =============================================================================

_testRRStr: #ResourceRequirementsSchema & {
	cpu: {
		request: "100m"
		limit:   "500m"
	}
	memory: {
		request: "128Mi"
		limit:   "256Mi"
	}
}

_testRRNum: #ResourceRequirementsSchema & {
	cpu: {
		request: 2
		limit:   8
	}
	memory: {
		request: 0.5
		limit:   4
	}
}

_testRRMixed: #ResourceRequirementsSchema & {
	cpu: {
		request: "100m"
		limit:   2
	}
	memory: {
		request: 0.5
		limit:   "1Gi"
	}
}

_testRRRequestOnly: #ResourceRequirementsSchema & {
	cpu: request:    "500m"
	memory: request: "256Mi"
}

_testRRLimitOnly: #ResourceRequirementsSchema & {
	cpu: limit:    "1000m"
	memory: limit: "512Mi"
}
