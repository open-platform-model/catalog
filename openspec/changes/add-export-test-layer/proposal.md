## Why

The current transformer tests only verify structural compatibility (`cue vet -c`) but cannot catch value-level bugs. A recent bug where number inputs (e.g., `cpu: 8`) weren't normalized to k8s canonical strings (e.g., `"8"`) was not caught by existing tests because k8s `#Quantity = number | string` makes fields non-concrete at the type level. We need value assertion tests that verify concrete output using `cue export`.

## What Changes

- Add Layer 3 to the test runner: `cue export`-based assertions that compare against JSON golden files
- Create `testdata/export/` directory structure in providers module
- Add 6 golden file test cases covering all transformer types (Deployment, StatefulSet, DaemonSet, CronJob, Job) with both string and number resource inputs
- Modify `Taskfile.yml` to run export assertions after existing test layers
- Require `jq` for normalized JSON comparison

## Capabilities

### New Capabilities
- `export-test-assertions`: Value-level testing for CUE transformers using `cue export` and golden file comparison

### Modified Capabilities
<!-- No existing spec requirements are changing - this is a pure testing addition -->

## Impact

**Affected systems:**
- `Taskfile.yml` test runner (add Layer 3 loop)
- `v0/providers/kubernetes/transformers/` test infrastructure (new testdata/export/ directory)

**Dependencies:**
- Requires `jq` for JSON normalization (already used in catalog workflows)

**SemVer classification:** PATCH - additive testing infrastructure, no API changes

**Modules affected:** `providers` (test infrastructure only, no published API changes)
