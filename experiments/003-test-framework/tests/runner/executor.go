package runner

import (
	"fmt"

	"cuelang.org/go/cue"
)

// Result holds the outcome of executing a test case.
type Result struct {
	// Value is the unified result (definition & input).
	Value cue.Value
	// Err is non-nil if structural validation failed.
	Err error
}

// Execute unifies the test case's definition with its input and validates the result.
// The moduleVal parameter is no longer used and kept only for API compatibility;
// definition is resolved directly from tc.Definition.
func Execute(ctx *cue.Context, tc TestCase) Result {
	// Convert input to JSON and recompile to strip closedness.
	// Input values extracted from within a #Test definition are closed structs,
	// which prevents unification from adding fields (like computed "out").
	// Recompiling from JSON produces an open struct.
	openInput, err := toOpenValue(ctx, tc.Input)
	if err != nil {
		return Result{
			Err: fmt.Errorf("cannot convert input to open struct: %w", err),
		}
	}

	// Unify definition with open input.
	result := tc.Definition.Unify(openInput)

	// Validate structurally (no concreteness requirement).
	// assertInvalid escalates to Validate(cue.Concrete(true)) when needed.
	valErr := result.Validate()

	return Result{
		Value: result,
		Err:   valErr,
	}
}

// toOpenValue converts a CUE value to an open struct by round-tripping through JSON.
func toOpenValue(ctx *cue.Context, v cue.Value) (cue.Value, error) {
	jsonBytes, err := v.MarshalJSON()
	if err != nil {
		return cue.Value{}, fmt.Errorf("marshal to JSON: %w", err)
	}
	return ctx.CompileBytes(jsonBytes), nil
}
