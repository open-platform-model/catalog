@if(test)

package schemas

// =============================================================================
// Quantity Normalization Tests
// =============================================================================

// ── #NormalizeCPU ────────────────────────────────────────────────

// Whole cores as integers
_testNormalizeCPU_Int1: (#NormalizeCPU & {_in: 1}).out
_testNormalizeCPU_Int1: "1000m"

_testNormalizeCPU_Int2: (#NormalizeCPU & {_in: 2}).out
_testNormalizeCPU_Int2: "2000m"

_testNormalizeCPU_Int8: (#NormalizeCPU & {_in: 8}).out
_testNormalizeCPU_Int8: "8000m"

// Fractional cores as floats
_testNormalizeCPU_Float05: (#NormalizeCPU & {_in: 0.5}).out
_testNormalizeCPU_Float05: "500m"

_testNormalizeCPU_Float025: (#NormalizeCPU & {_in: 0.25}).out
_testNormalizeCPU_Float025: "250m"

_testNormalizeCPU_Float15: (#NormalizeCPU & {_in: 1.5}).out
_testNormalizeCPU_Float15: "1500m"

_testNormalizeCPU_Float01: (#NormalizeCPU & {_in: 0.1}).out
_testNormalizeCPU_Float01: "100m"

// String passthrough (millicore format)
_testNormalizeCPU_String500m: (#NormalizeCPU & {_in: "500m"}).out
_testNormalizeCPU_String500m: "500m"

_testNormalizeCPU_String2000m: (#NormalizeCPU & {_in: "2000m"}).out
_testNormalizeCPU_String2000m: "2000m"

_testNormalizeCPU_String100m: (#NormalizeCPU & {_in: "100m"}).out
_testNormalizeCPU_String100m: "100m"

// Edge cases: zero and minimum
_testNormalizeCPU_Zero: (#NormalizeCPU & {_in: 0}).out
_testNormalizeCPU_Zero: "0m"

_testNormalizeCPU_Float001: (#NormalizeCPU & {_in: 0.001}).out
_testNormalizeCPU_Float001: "1m"

_testNormalizeCPU_String1m: (#NormalizeCPU & {_in: "1m"}).out
_testNormalizeCPU_String1m: "1m"

_testNormalizeCPU_String0m: (#NormalizeCPU & {_in: "0m"}).out
_testNormalizeCPU_String0m: "0m"

// Edge cases: large values
_testNormalizeCPU_Int16: (#NormalizeCPU & {_in: 16}).out
_testNormalizeCPU_Int16: "16000m"

_testNormalizeCPU_Int32: (#NormalizeCPU & {_in: 32}).out
_testNormalizeCPU_Int32: "32000m"

_testNormalizeCPU_Int64: (#NormalizeCPU & {_in: 64}).out
_testNormalizeCPU_Int64: "64000m"

_testNormalizeCPU_String64000m: (#NormalizeCPU & {_in: "64000m"}).out
_testNormalizeCPU_String64000m: "64000m"

// ── #NormalizeMemory ─────────────────────────────────────────────

// Whole GiB as integers (should use Gi suffix)
_testNormalizeMemory_Int1: (#NormalizeMemory & {_in: 1}).out
_testNormalizeMemory_Int1: "1Gi"

_testNormalizeMemory_Int4: (#NormalizeMemory & {_in: 4}).out
_testNormalizeMemory_Int4: "4Gi"

_testNormalizeMemory_Int16: (#NormalizeMemory & {_in: 16}).out
_testNormalizeMemory_Int16: "16Gi"

// Fractional GiB as floats (should convert to Mi)
_testNormalizeMemory_Float05: (#NormalizeMemory & {_in: 0.5}).out
_testNormalizeMemory_Float05: "512Mi"

_testNormalizeMemory_Float15: (#NormalizeMemory & {_in: 1.5}).out
_testNormalizeMemory_Float15: "1536Mi"

_testNormalizeMemory_Float025: (#NormalizeMemory & {_in: 0.25}).out
_testNormalizeMemory_Float025: "256Mi"

_testNormalizeMemory_Float0125: (#NormalizeMemory & {_in: 0.125}).out
_testNormalizeMemory_Float0125: "128Mi"

// String passthrough (Mi/Gi format)
_testNormalizeMemory_String256Mi: (#NormalizeMemory & {_in: "256Mi"}).out
_testNormalizeMemory_String256Mi: "256Mi"

_testNormalizeMemory_String4Gi: (#NormalizeMemory & {_in: "4Gi"}).out
_testNormalizeMemory_String4Gi: "4Gi"

_testNormalizeMemory_String1024Mi: (#NormalizeMemory & {_in: "1024Mi"}).out
_testNormalizeMemory_String1024Mi: "1024Mi"

_testNormalizeMemory_String8Gi: (#NormalizeMemory & {_in: "8Gi"}).out
_testNormalizeMemory_String8Gi: "8Gi"

// Edge cases: zero and minimum
_testNormalizeMemory_Zero: (#NormalizeMemory & {_in: 0}).out
_testNormalizeMemory_Zero: "0Gi"

_testNormalizeMemory_String0Mi: (#NormalizeMemory & {_in: "0Mi"}).out
_testNormalizeMemory_String0Mi: "0Mi"

_testNormalizeMemory_String1Mi: (#NormalizeMemory & {_in: "1Mi"}).out
_testNormalizeMemory_String1Mi: "1Mi"

_testNormalizeMemory_String0Gi: (#NormalizeMemory & {_in: "0Gi"}).out
_testNormalizeMemory_String0Gi: "0Gi"

// Edge cases: small fractions (binary-exact)
_testNormalizeMemory_Float0625: (#NormalizeMemory & {_in: 0.0625}).out
_testNormalizeMemory_Float0625: "64Mi"

_testNormalizeMemory_Float001953125: (#NormalizeMemory & {_in: 0.001953125}).out
_testNormalizeMemory_Float001953125: "2Mi"

// Edge cases: large values
_testNormalizeMemory_Int32: (#NormalizeMemory & {_in: 32}).out
_testNormalizeMemory_Int32: "32Gi"

_testNormalizeMemory_Int64: (#NormalizeMemory & {_in: 64}).out
_testNormalizeMemory_Int64: "64Gi"

_testNormalizeMemory_Int128: (#NormalizeMemory & {_in: 128}).out
_testNormalizeMemory_Int128: "128Gi"

_testNormalizeMemory_String32768Mi: (#NormalizeMemory & {_in: "32768Mi"}).out
_testNormalizeMemory_String32768Mi: "32768Mi"

_testNormalizeMemory_String128Gi: (#NormalizeMemory & {_in: "128Gi"}).out
_testNormalizeMemory_String128Gi: "128Gi"
