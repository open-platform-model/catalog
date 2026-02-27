package tests

import (
	"os"
	"path/filepath"
	"testing"

	"experiments/003-test-framework/tests/runner"
)

// experimentDir returns the root of the experiment directory.
func experimentDir() string {
	dir, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	return filepath.Join(dir, "..")
}

// runTestSuite loads a CUE package and runs all discovered test groups.
func runTestSuite(t *testing.T, pkgDir string, pattern string) {
	t.Helper()

	ctx := runner.NewContext()

	mod, err := runner.LoadModule(ctx, pkgDir, pattern, []string{"test"})
	if err != nil {
		t.Fatalf("failed to load module: %v", err)
	}

	tests, groupNames, err := runner.DiscoverTests(mod)
	if err != nil {
		t.Fatalf("failed to discover tests: %v", err)
	}

	if len(tests) == 0 {
		t.Fatal("no test groups found in #tests")
	}

	total := 0
	for _, group := range groupNames {
		cases := tests[group]
		total += len(cases)
		t.Run(group, func(t *testing.T) {
			for _, tc := range cases {
				tc := tc // capture
				t.Run(tc.Name, func(t *testing.T) {
					result := runner.Execute(ctx, tc)
					runner.RunAssertions(t, result, tc)
				})
			}
		})
	}

	t.Logf("Discovered %d tests across %d groups", total, len(groupNames))
}

func TestSchemas(t *testing.T) {
	runTestSuite(t, filepath.Join(experimentDir(), "v0", "schemas"), "./tests")
}

func TestCore(t *testing.T) {
	runTestSuite(t, filepath.Join(experimentDir(), "v0", "core"), "./tests")
}

func TestResourceContainer(t *testing.T) {
	runTestSuite(t, filepath.Join(experimentDir(), "v0", "resources", "workload"), "./tests")
}

func TestResourceConfigMaps(t *testing.T) {
	runTestSuite(t, filepath.Join(experimentDir(), "v0", "resources", "config"), "./tests")
}

func TestTraitScaling(t *testing.T) {
	runTestSuite(t, filepath.Join(experimentDir(), "v0", "traits", "workload"), "./tests")
}

func TestTraitExpose(t *testing.T) {
	runTestSuite(t, filepath.Join(experimentDir(), "v0", "traits", "network"), "./tests")
}
