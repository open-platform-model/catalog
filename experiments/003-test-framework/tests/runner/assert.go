package runner

import (
	"fmt"
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
		assertOutput(t, result, tc)
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
			"    %stest:%s        %s%s%s\n"+
			"    %sinput:%s      %s%s%s\n"+
			"    %serror:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Name, cReset,
			cCyan, cReset, cDim, inputStr, cReset,
			cCyan, cReset, cRed, formatCUEError(result.Err), cReset,
		)
	}
}

// assertInvalid checks that unification failed, and optionally checks the error
// string against the `error` CUE constraint.
//
// Uses Validate(cue.Concrete(true)) so that missing required fields (which leave
// the result inconcrete rather than producing a constraint error) are also caught.
func assertInvalid(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	spec := tc.Assert

	// If structural validation passed, try the stricter concrete check.
	// Missing required fields produce inconcrete values rather than errors, so
	// Validate() alone would miss them.
	err := result.Err
	if err == nil {
		err = result.Value.Validate(cue.Concrete(true))
	}
	result.Err = err

	if result.Err == nil {
		inputStr := formatInput(tc.Input)
		outputStr := ""
		if jsonBytes, err := result.Value.MarshalJSON(); err == nil {
			outputStr = string(jsonBytes)
		}
		t.Fatalf("\n"+
			"    %s%sexpected invalid, but validation passed%s\n"+
			"    %stest:%s        %s%s%s\n"+
			"    %sinput:%s      %s%s%s\n"+
			"    %soutput:%s     %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Name, cReset,
			cCyan, cReset, cDim, inputStr, cReset,
			cCyan, cReset, cDim, outputStr, cReset,
		)
		return
	}

	// Optionally check the error string against a CUE constraint.
	if spec.Error != nil {
		assertError(t, result, tc)
	}
}

// assertError checks the error string against the `error` CUE constraint.
// The error string is compiled as a CUE string value and unified with the constraint.
func assertError(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	if result.Err == nil {
		return
	}

	ctx := result.Value.Context()
	errMsg := result.Err.Error()

	// Compile the error string as a CUE quoted string value.
	errVal := ctx.CompileString(fmt.Sprintf("%q", errMsg))
	if errVal.Err() != nil {
		t.Errorf("internal: cannot compile error string as CUE value: %v", errVal.Err())
		return
	}

	// Unify the compiled error string with the constraint from the test.
	unified := errVal.Unify(*tc.Assert.Error)
	if err := unified.Validate(cue.Concrete(true)); err != nil {
		// Format the constraint for display.
		constraintStr := fmt.Sprintf("%v", *tc.Assert.Error)
		t.Errorf("\n"+
			"    %s%serror constraint not satisfied%s\n"+
			"    %stest:%s        %s%s%s\n"+
			"    %sconstraint:%s  %s%s%s\n"+
			"    %sgot:%s        %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Name, cReset,
			cCyan, cReset, cGreen, constraintStr, cReset,
			cCyan, cReset, cRed, errMsg, cReset,
		)
	}
}

// assertOutput tree-walks the `output` CUE value and checks each leaf against
// the corresponding path in the result. This avoids closedness issues that would
// arise from directly unifying the full output value with the result.
func assertOutput(t *testing.T, result Result, tc TestCase) {
	t.Helper()
	if tc.Assert.Output == nil {
		return
	}
	walkOutput(t, result.Value, *tc.Assert.Output, cue.Path{}, tc)
}

// walkOutput recursively walks `expected`, and for each leaf node checks it
// against the value at the same path in `result`.
func walkOutput(t *testing.T, result cue.Value, expected cue.Value, path cue.Path, tc TestCase) {
	t.Helper()

	// If expected is a struct, recurse into its fields.
	if expected.IncompleteKind() == cue.StructKind {
		iter, err := expected.Fields(cue.All())
		if err != nil {
			t.Errorf("output: cannot iterate struct at path %q: %v", path, err)
			return
		}
		for iter.Next() {
			sel := iter.Selector()
			childPath := cue.MakePath(append(path.Selectors(), sel)...)
			childExpected := iter.Value()
			childResult := result.LookupPath(cue.MakePath(sel))
			walkOutput(t, childResult, childExpected, childPath, tc)
		}
		return
	}

	// Leaf node: unify expected constraint with result value.
	pathStr := fmt.Sprintf("%v", path)

	if !result.Exists() {
		t.Errorf("\n"+
			"    %s%soutput field not found%s\n"+
			"    %stest:%s        %s%s%s\n"+
			"    %spath:%s        %s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Name, cReset,
			cCyan, cReset, pathStr,
		)
		return
	}
	if result.Err() != nil {
		t.Errorf("\n"+
			"    %s%soutput field error%s\n"+
			"    %stest:%s        %s%s%s\n"+
			"    %spath:%s        %s\n"+
			"    %serror:%s       %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Name, cReset,
			cCyan, cReset, pathStr,
			cCyan, cReset, cRed, formatCUEError(result.Err()), cReset,
		)
		return
	}

	unified := result.Unify(expected)
	if err := unified.Validate(cue.Concrete(true)); err != nil {
		actualStr, _ := formatValue(result)
		expectedStr := fmt.Sprintf("%v", expected)
		t.Errorf("\n"+
			"    %s%soutput mismatch%s\n"+
			"    %stest:%s        %s%s%s\n"+
			"    %spath:%s        %s\n"+
			"    %sexpected:%s    %s%s%s\n"+
			"    %sactual:%s      %s%s%s\n",
			cBold, cRed, cReset,
			cCyan, cReset, cYellow, tc.Name, cReset,
			cCyan, cReset, pathStr,
			cCyan, cReset, cGreen, expectedStr, cReset,
			cCyan, cReset, cRed, actualStr, cReset,
		)
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
