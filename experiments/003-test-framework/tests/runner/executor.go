package runner

import (
	"fmt"

	"cuelang.org/go/cue"
)

// Result holds the outcome of executing a test case.
type Result struct {
	// Value is the unified result (definition & input).
	Value cue.Value
	// Err is non-nil if unification or validation failed.
	Err error
}

// Execute resolves the definition by name from the module and unifies it
// with the test case input. Returns the result and any validation error.
func Execute(ctx *cue.Context, moduleVal cue.Value, tc TestCase) Result {
	// Resolve the definition by its string path (e.g., "#NormalizeCPU")
	def := moduleVal.LookupPath(cue.ParsePath(tc.Definition))
	if !def.Exists() {
		return Result{
			Err: fmt.Errorf("definition %s not found", tc.Definition),
		}
	}
	if def.Err() != nil {
		return Result{
			Err: fmt.Errorf("definition %s has error: %w", tc.Definition, def.Err()),
		}
	}

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

	// Unify definition with open input
	result := def.Unify(openInput)

	// Validate the result — checks for constraint violations.
	// When concrete=true (default), also checks that all fields are concrete.
	// When concrete=false, only checks structural validity (useful for definitions
	// with hidden inconcrete fields like #spec).
	var valErr error
	if tc.Assert.Concrete {
		valErr = result.Validate(cue.Concrete(true))
	} else {
		valErr = result.Validate()
	}

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
