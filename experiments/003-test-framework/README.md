# Experiment 003: CUE Test Framework

Validate a new test framework design where test definitions are written in CUE
and processed by a Go test runner. The Go runner provides richer assertions than
CUE unification alone: exact value comparison, negative validation (expected
failures), field-level checks, and clear error reporting.

## Problem

The current test setup has two layers:

1. **CUE unification tests** (`*_tests.cue`) — hidden fields unified with
   definitions, checked for concreteness via `cue vet -c -t test`.
2. **YAML fixtures** (`testdata/*.yaml`) — external data files validated against
   definitions using filename conventions (`_valid_` / `_invalid_`).

Limitations:

- No way to assert **computed output values** (only pass/fail).
- **Negative tests** require separate YAML files with a bash harness.
- **Error messages** on failure are CUE's raw "conflicting values" output.
- **No schema contract testing** — structural API changes go undetected.
- ~150 lines of bash in Taskfile.yml to orchestrate everything.

## Solution

A three-part design:

1. **`testkit` CUE module** — defines `#Test`, `#Assert`, `#FieldCheck` schemas
   for declaring test cases as structured data.
2. **Test definitions in CUE** — `#tests` definitions in `*_tests.cue` files
   describe inputs, target definitions, and expected outcomes. They are data, not
   evaluated unifications.
3. **Go test runner** — loads CUE modules, discovers `#tests`, resolves
   definitions, performs unification, and runs assertions with clear reporting.

## Scope

This experiment migrates `v0/schemas/quantity_tests.cue` (and related YAML
fixtures) to validate the approach end-to-end:

- ~20 `#NormalizeCPU` positive tests with field value assertions
- ~20 `#NormalizeMemory` positive tests with field value assertions
- ~15 `#ResourceRequirementsSchema` tests (positive + negative)

## Structure

```
experiments/003-test-framework/
  v0/
    testkit/
      test.cue                  # #Tests, #Test, #Assert, #FieldCheck
    schemas/                    # Copy of v0/schemas, modified
      cue.mod/
        module.cue              # lang v0.16.0
        pkg/opmodel.dev/testkit@v0/
          test.cue              # Copy of testkit/test.cue
      *.cue                     # Schema source files
      quantity_tests.cue        # Rewritten in new format
  tests/                        # Go test runner
    go.mod
    runner/
      loader.go                 # Load CUE modules, discover #tests
      executor.go               # Resolve definitions, unify inputs
      assert.go                 # Assertion engine
    runner_test.go              # go test entry point
```

## Running

```bash
# Verify CUE definitions parse correctly
cd experiments/003-test-framework/v0/schemas
cue vet -t test ./...

# Run Go tests
cd experiments/003-test-framework/tests
go test -v ./...
```

## Success Criteria

- [ ] Go can load CUE modules with `@if(test)` build tag
- [ ] Go can access `#tests` definitions
- [ ] Go can resolve definitions by string name (e.g., `"#NormalizeCPU"`)
- [ ] Go can unify input with definitions and detect success/failure
- [ ] Positive tests pass with correct field value assertions
- [ ] Negative tests correctly detect validation failures
- [ ] Test output is clear: group/name hierarchy, "expected X, got Y" on failure
- [ ] Test definitions are concise and readable vs the old format
