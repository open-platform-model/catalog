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
	Group      string    // group key from #tests (e.g. "#PortSchema")
	Definition cue.Value // resolved CUE definition value
	Input      cue.Value
	Assert     AssertSpec
}

// AssertSpec holds the assertion configuration for a test case.
type AssertSpec struct {
	Valid  bool
	Output *cue.Value // CUE expression tree-walked against result (valid=true)
	Error  *cue.Value // CUE constraint on error string (valid=false)
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

		cases, err := decodeTestCases(groupVal, groupName)
		if err != nil {
			return nil, nil, fmt.Errorf("group %q: %w", groupName, err)
		}
		result[groupName] = cases
		groupNames = append(groupNames, groupName)
	}

	sort.Strings(groupNames)
	return result, groupNames, nil
}

func decodeTestCases(listVal cue.Value, groupName string) ([]TestCase, error) {
	iter, err := listVal.List()
	if err != nil {
		return nil, fmt.Errorf("expected list: %w", err)
	}

	var cases []TestCase
	for iter.Next() {
		tc, err := decodeTestCase(iter.Value(), groupName)
		if err != nil {
			return nil, err
		}
		cases = append(cases, tc)
	}
	return cases, nil
}

func decodeTestCase(val cue.Value, groupName string) (TestCase, error) {
	var tc TestCase
	tc.Group = groupName

	nameVal := val.LookupPath(cue.ParsePath("name"))
	if nameVal.Err() != nil {
		return tc, fmt.Errorf("missing name: %w", nameVal.Err())
	}
	name, err := nameVal.String()
	if err != nil {
		return tc, fmt.Errorf("name must be string: %w", err)
	}
	tc.Name = name

	// definition is now a CUE value reference, not a string.
	defVal := val.LookupPath(cue.ParsePath("definition"))
	if !defVal.Exists() {
		return tc, fmt.Errorf("test %q: missing definition", name)
	}
	if defVal.Err() != nil {
		return tc, fmt.Errorf("test %q: definition error: %w", name, defVal.Err())
	}
	tc.Definition = defVal

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

	// output: CUE expression for tree-walking against the result
	outputVal := val.LookupPath(cue.ParsePath("output"))
	if outputVal.Exists() && outputVal.Err() == nil {
		spec.Output = &outputVal
	}

	// error: CUE constraint on the error string
	errorVal := val.LookupPath(cue.ParsePath("error"))
	if errorVal.Exists() && errorVal.Err() == nil {
		spec.Error = &errorVal
	}

	return spec, nil
}
