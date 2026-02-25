package runner

import (
	"fmt"
	"sort"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

// TestCase holds a decoded test case from CUE.
type TestCase struct {
	Name       string
	Definition string
	Input      cue.Value
	Assert     AssertSpec
}

// AssertSpec holds the assertion configuration for a test case.
type AssertSpec struct {
	Valid         bool
	Concrete      bool
	Equal         *cue.Value
	Contains      *cue.Value
	Fields        map[string]FieldCheck
	ErrorContains string
	ErrorPath     string
}

// FieldCheck holds assertions for a single field.
type FieldCheck struct {
	Equals *cue.Value
}

// LoadModule loads a CUE module from a directory with the given build tags.
// The pattern parameter specifies which packages to load (e.g., "./tests").
// Returns the unified cue.Value for the entire package.
func LoadModule(ctx *cue.Context, dir string, pattern string, tags []string) (cue.Value, error) {
	cfg := &load.Config{
		Dir:  dir,
		Tags: tags,
	}
	instances := load.Instances([]string{pattern}, cfg)
	if len(instances) == 0 {
		return cue.Value{}, fmt.Errorf("no instances found in %s", dir)
	}
	inst := instances[0]
	if inst.Err != nil {
		return cue.Value{}, fmt.Errorf("load error: %w", inst.Err)
	}
	val := ctx.BuildInstance(inst)
	if val.Err() != nil {
		return cue.Value{}, fmt.Errorf("build error: %w", val.Err())
	}
	return val, nil
}

// NewContext creates a new CUE context.
func NewContext() *cue.Context {
	return cuecontext.New()
}

// DiscoverTests extracts #tests from a loaded module value.
// Returns a map of group name → test cases, sorted by group name.
func DiscoverTests(val cue.Value) (map[string][]TestCase, []string, error) {
	testsVal := val.LookupPath(cue.ParsePath("#tests"))
	if !testsVal.Exists() {
		return nil, nil, fmt.Errorf("#tests definition not found in module")
	}
	if testsVal.Err() != nil {
		return nil, nil, fmt.Errorf("#tests lookup error: %w", testsVal.Err())
	}

	result := make(map[string][]TestCase)
	var groupNames []string

	// Iterate over groups (top-level fields in #tests)
	iter, err := testsVal.Fields(cue.All())
	if err != nil {
		return nil, nil, fmt.Errorf("cannot iterate #tests fields: %w", err)
	}
	for iter.Next() {
		groupName := iter.Selector().String()
		groupVal := iter.Value()

		cases, err := decodeTestCases(groupVal)
		if err != nil {
			return nil, nil, fmt.Errorf("group %q: %w", groupName, err)
		}
		result[groupName] = cases
		groupNames = append(groupNames, groupName)
	}

	sort.Strings(groupNames)
	return result, groupNames, nil
}

func decodeTestCases(listVal cue.Value) ([]TestCase, error) {
	iter, err := listVal.List()
	if err != nil {
		return nil, fmt.Errorf("expected list: %w", err)
	}

	var cases []TestCase
	for iter.Next() {
		tc, err := decodeTestCase(iter.Value())
		if err != nil {
			return nil, err
		}
		cases = append(cases, tc)
	}
	return cases, nil
}

func decodeTestCase(val cue.Value) (TestCase, error) {
	var tc TestCase

	nameVal := val.LookupPath(cue.ParsePath("name"))
	if nameVal.Err() != nil {
		return tc, fmt.Errorf("missing name: %w", nameVal.Err())
	}
	name, err := nameVal.String()
	if err != nil {
		return tc, fmt.Errorf("name must be string: %w", err)
	}
	tc.Name = name

	defVal := val.LookupPath(cue.ParsePath("definition"))
	if defVal.Err() != nil {
		return tc, fmt.Errorf("test %q: missing definition: %w", name, defVal.Err())
	}
	def, err := defVal.String()
	if err != nil {
		return tc, fmt.Errorf("test %q: definition must be string: %w", name, err)
	}
	tc.Definition = def

	tc.Input = val.LookupPath(cue.ParsePath("input"))
	if !tc.Input.Exists() {
		return tc, fmt.Errorf("test %q: missing input", name)
	}

	tc.Assert, err = decodeAssert(val.LookupPath(cue.ParsePath("assert")))
	if err != nil {
		return tc, fmt.Errorf("test %q: %w", name, err)
	}

	return tc, nil
}

func decodeAssert(val cue.Value) (AssertSpec, error) {
	var spec AssertSpec

	// valid defaults to true
	spec.Valid = true
	validVal := val.LookupPath(cue.ParsePath("valid"))
	if validVal.Exists() && validVal.Err() == nil {
		v, err := validVal.Bool()
		if err == nil {
			spec.Valid = v
		}
	}

	// concrete defaults to true
	spec.Concrete = true
	concreteVal := val.LookupPath(cue.ParsePath("concrete"))
	if concreteVal.Exists() && concreteVal.Err() == nil {
		v, err := concreteVal.Bool()
		if err == nil {
			spec.Concrete = v
		}
	}

	// equal
	equalVal := val.LookupPath(cue.ParsePath("equal"))
	if equalVal.Exists() && equalVal.Err() == nil {
		spec.Equal = &equalVal
	}

	// contains
	containsVal := val.LookupPath(cue.ParsePath("contains"))
	if containsVal.Exists() && containsVal.Err() == nil {
		spec.Contains = &containsVal
	}

	// fields
	fieldsVal := val.LookupPath(cue.ParsePath("fields"))
	if fieldsVal.Exists() && fieldsVal.Err() == nil {
		spec.Fields = make(map[string]FieldCheck)
		fIter, err := fieldsVal.Fields(cue.All())
		if err == nil {
			for fIter.Next() {
				fieldName := fIter.Selector().String()
				fc, err := decodeFieldCheck(fIter.Value())
				if err != nil {
					return spec, fmt.Errorf("field %q: %w", fieldName, err)
				}
				spec.Fields[fieldName] = fc
			}
		}
	}

	// errorContains
	ecVal := val.LookupPath(cue.ParsePath("errorContains"))
	if ecVal.Exists() && ecVal.Err() == nil {
		s, err := ecVal.String()
		if err == nil {
			spec.ErrorContains = s
		}
	}

	// errorPath
	epVal := val.LookupPath(cue.ParsePath("errorPath"))
	if epVal.Exists() && epVal.Err() == nil {
		s, err := epVal.String()
		if err == nil {
			spec.ErrorPath = s
		}
	}

	return spec, nil
}

func decodeFieldCheck(val cue.Value) (FieldCheck, error) {
	var fc FieldCheck

	equalsVal := val.LookupPath(cue.ParsePath("equals"))
	if equalsVal.Exists() && equalsVal.Err() == nil {
		fc.Equals = &equalsVal
	}

	return fc, nil
}
