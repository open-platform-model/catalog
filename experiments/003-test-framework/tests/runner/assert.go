package runner

import (
	"fmt"
	"strings"
	"testing"

	"cuelang.org/go/cue"
)

// ANSI color codes for terminal output.
const (
	cRed    = "\033[31m"
	cGreen  = "\033[32m"
	cYellow = "\033[33m"
	cCyan   = "\033[36m"
	cDim    = "\033[2m"
	cBold   = "\033[1m"
	cReset  = "\033[0m"
)

// RunAssertions checks all assertions for a test case result.
func RunAssertions(t *testing.T, result Result, tc TestCase) {
	t.Helper()

	spec := tc.Assert
	if spec.Valid {
		assertValid(t, result, tc)
		if t.Failed() {
			return
		}
		assertEqual(t, result, tc)
		assertContains(t, result, tc)
		assertFields(t, result, tc)
	} else {
		assertInvalid(t, result, tc)
	}
}

// assertValid checks that unification succeeded.
func assertValid(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	if result.Err != nil {
		inputStr := formatInput(tc.Input)
		t.Fatalf("\n"+
			"    %s%sexpected valid, but got error%s\n"+
			"    %sdefinition:%s  %s%s%s\n"+
			"    %sconcrete:%s   %v\n"+
			"    %sinput:%s      %s%s%s\n"+
			"    %serror:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Definition, cReset,
			cCyan, cReset, tc.Assert.Concrete,
			cCyan, cReset, cDim, inputStr, cReset,
			cCyan, cReset, cRed, formatCUEError(result.Err), cReset,
		)
	}
}

// assertInvalid checks that unification failed, and optionally checks error properties.
func assertInvalid(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	spec := tc.Assert
	if result.Err == nil {
		inputStr := formatInput(tc.Input)
		outputStr := ""
		if jsonBytes, err := result.Value.MarshalJSON(); err == nil {
			outputStr = string(jsonBytes)
		}
		t.Fatalf("\n"+
			"    %s%sexpected invalid, but validation passed%s\n"+
			"    %sdefinition:%s  %s%s%s\n"+
			"    %sconcrete:%s   %v\n"+
			"    %sinput:%s      %s%s%s\n"+
			"    %soutput:%s     %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Definition, cReset,
			cCyan, cReset, spec.Concrete,
			cCyan, cReset, cDim, inputStr, cReset,
			cCyan, cReset, cDim, outputStr, cReset,
		)
	}

	errMsg := result.Err.Error()

	if spec.ErrorContains != "" {
		if !strings.Contains(errMsg, spec.ErrorContains) {
			t.Errorf("\n"+
				"    %s%serror message mismatch%s\n"+
				"    %sdefinition:%s  %s%s%s\n"+
				"    %sexpected:%s   error containing %s%q%s\n"+
				"    %sgot:%s        %s%s%s\n",
				cBold, cRed, cReset,
				cCyan, cReset, cYellow, tc.Definition, cReset,
				cCyan, cReset, cGreen, spec.ErrorContains, cReset,
				cCyan, cReset, cRed, errMsg, cReset,
			)
		}
	}

	if spec.ErrorPath != "" {
		if !strings.Contains(errMsg, spec.ErrorPath) {
			t.Errorf("\n"+
				"    %s%serror path mismatch%s\n"+
				"    %sdefinition:%s  %s%s%s\n"+
				"    %sexpected:%s   error at path %s%q%s\n"+
				"    %sgot:%s        %s%s%s\n",
				cBold, cRed, cReset,
				cCyan, cReset, cYellow, tc.Definition, cReset,
				cCyan, cReset, cGreen, spec.ErrorPath, cReset,
				cCyan, cReset, cRed, errMsg, cReset,
			)
		}
	}
}

// assertEqual checks that the full output matches the expected value.
func assertEqual(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	spec := tc.Assert
	if spec.Equal == nil {
		return
	}

	unified := result.Value.Unify(*spec.Equal)
	if err := unified.Validate(cue.Concrete(true)); err != nil {
		actualJSON, _ := result.Value.MarshalJSON()
		expectedJSON, _ := spec.Equal.MarshalJSON()
		t.Errorf("\n"+
			"    %s%soutput mismatch%s\n"+
			"    %sdefinition:%s  %s%s%s\n"+
			"    %sexpected:%s   %s%s%s\n"+
			"    %sactual:%s     %s%s%s\n"+
			"    %serror:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Definition, cReset,
			cCyan, cReset, cGreen, string(expectedJSON), cReset,
			cCyan, cReset, cRed, string(actualJSON), cReset,
			cCyan, cReset, cDim, err, cReset,
		)
	}
}

// assertContains checks that the output contains the expected subset of fields/values.
func assertContains(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	spec := tc.Assert
	if spec.Contains == nil {
		return
	}

	unified := result.Value.Unify(*spec.Contains)
	if err := unified.Validate(cue.Concrete(true)); err != nil {
		t.Errorf("\n"+
			"    %s%soutput does not contain expected values%s\n"+
			"    %sdefinition:%s  %s%s%s\n"+
			"    %serror:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Definition, cReset,
			cCyan, cReset, cRed, formatCUEError(err), cReset,
		)
	}
}

// assertFields checks per-field assertions on the output.
func assertFields(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	if len(tc.Assert.Fields) == 0 {
		return
	}

	for fieldPath, check := range tc.Assert.Fields {
		assertField(t, result, tc, fieldPath, check)
	}
}

// assertField checks a single field assertion.
// Field paths may arrive quoted from CUE (e.g., "metadata.fqn" when used as a
// struct key containing dots). Strip surrounding quotes so cue.ParsePath
// interprets them as dotted paths.
func assertField(t *testing.T, result Result, tc TestCase, fieldPath string, check FieldCheck) {
	t.Helper()

	// Strip surrounding quotes if present (CUE quoted struct keys)
	cleanPath := fieldPath
	if len(cleanPath) >= 2 && cleanPath[0] == '"' && cleanPath[len(cleanPath)-1] == '"' {
		cleanPath = cleanPath[1 : len(cleanPath)-1]
	}

	fieldVal := result.Value.LookupPath(cue.ParsePath(cleanPath))
	if !fieldVal.Exists() {
		t.Errorf("\n"+
			"    %s%sfield not found%s\n"+
			"    %sdefinition:%s  %s%s%s\n"+
			"    %sfield:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Definition, cReset,
			cCyan, cReset, cRed, cleanPath, cReset,
		)
		return
	}
	if fieldVal.Err() != nil {
		t.Errorf("\n"+
			"    %s%sfield error%s\n"+
			"    %sdefinition:%s  %s%s%s\n"+
			"    %sfield:%s      %s\n"+
			"    %serror:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Definition, cReset,
			cCyan, cReset, cleanPath,
			cCyan, cReset, cRed, formatCUEError(fieldVal.Err()), cReset,
		)
		return
	}

	if check.Equals != nil {
		assertFieldEquals(t, tc, cleanPath, fieldVal, *check.Equals)
	}
}

// assertFieldEquals checks that a field value equals the expected value.
func assertFieldEquals(t *testing.T, tc TestCase, fieldPath string, actual cue.Value, expected cue.Value) {
	t.Helper()

	actualStr, aErr := formatValue(actual)
	expectedStr, eErr := formatValue(expected)

	unified := actual.Unify(expected)
	if err := unified.Validate(cue.Concrete(true)); err != nil {
		if aErr == nil && eErr == nil {
			t.Errorf("\n"+
				"    %s%sfield value mismatch%s\n"+
				"    %sdefinition:%s  %s%s%s\n"+
				"    %sfield:%s      %s\n"+
				"    %sexpected:%s   %s%s%s\n"+
				"    %sactual:%s     %s%s%s\n",
				cBold, cRed, cReset,
				cCyan, cReset, cYellow, tc.Definition, cReset,
				cCyan, cReset, fieldPath,
				cCyan, cReset, cGreen, expectedStr, cReset,
				cCyan, cReset, cRed, actualStr, cReset,
			)
		} else {
			t.Errorf("\n"+
				"    %s%sfield value mismatch%s\n"+
				"    %sdefinition:%s  %s%s%s\n"+
				"    %sfield:%s      %s\n"+
				"    %serror:%s      %s%s%s\n",
				cBold, cRed, cReset,
				cCyan, cReset, cYellow, tc.Definition, cReset,
				cCyan, cReset, fieldPath,
				cCyan, cReset, cRed, formatCUEError(err), cReset,
			)
		}
	}
}

// formatInput marshals a CUE value to JSON for display, with a truncation limit.
func formatInput(v cue.Value) string {
	jsonBytes, err := v.MarshalJSON()
	if err != nil {
		return "<cannot marshal input>"
	}
	s := string(jsonBytes)
	if len(s) > 200 {
		return s[:197] + "..."
	}
	return s
}

// formatValue formats a CUE value for display in error messages.
func formatValue(v cue.Value) (string, error) {
	switch v.IncompleteKind() {
	case cue.StringKind:
		s, err := v.String()
		if err == nil {
			return fmt.Sprintf("%q", s), nil
		}
	case cue.IntKind:
		i, err := v.Int64()
		if err == nil {
			return fmt.Sprintf("%d", i), nil
		}
	case cue.FloatKind:
		f, err := v.Float64()
		if err == nil {
			return fmt.Sprintf("%g", f), nil
		}
	case cue.BoolKind:
		b, err := v.Bool()
		if err == nil {
			return fmt.Sprintf("%t", b), nil
		}
	}

	jsonBytes, err := v.MarshalJSON()
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// formatCUEError formats a CUE error for readable test output.
func formatCUEError(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}
