## Context

The catalog test runner (Taskfile.yml) has 2 test layers:
1. **Layer 1**: `*_tests.cue` files with `@if(test)` tag → validated via `cue vet -c -t test`
2. **Layer 2**: `testdata/*.yaml` files → validated via `cue vet -d '#Definition'`

Layer 1 cannot verify concrete output values for transformer tests because k8s resource fields are typed as `#Quantity = number | string` — a disjunction that remains non-concrete at the type level even when unified with concrete values. `cue vet -c` rejects non-concrete types.

However, `cue export -e <expression>` resolves disjunctions during serialization and produces concrete JSON output. We can leverage this to create value assertion tests.

## Goals / Non-Goals

**Goals:**
- Catch value-level bugs (e.g., number→string normalization failures) that structural tests miss
- Verify all 5 transformer types produce correct resource outputs for both string and number inputs
- Integrate seamlessly into existing test workflow without breaking current tests
- Use simple, maintainable golden file pattern that's easy to update

**Non-Goals:**
- Replace existing Layer 1/2 tests (they serve different purposes)
- Test every transformer output field (focus on resource normalization which is the bug-prone area)
- Create a general-purpose CUE testing framework

## Decisions

### D1: Use `cue export` + golden files vs extending `cue vet -c`

**Choice:** `cue export` + JSON golden files

**Rationale:**
- `cue vet -c` fundamentally cannot verify `number | string` fields are concrete
- `cue export` produces serialized JSON that can be diffed
- Golden files are simple, explicit, and easy to review in code review
- Pattern is familiar to developers (similar to snapshot testing)

**Alternatives considered:**
- Custom CUE test harness: Over-engineered for this specific need
- Inline value assertions in CUE: Impossible due to k8s type constraints

### D2: File structure - `.expr` + `.json` pairs vs single manifest file

**Choice:** Separate `.expr` and `.json` files (e.g., `deploy-string-resources.expr` + `deploy-string-resources.json`)

**Rationale:**
- Each test case is self-contained and easy to locate
- Adding new tests doesn't require editing a central manifest
- File pairing is obvious from naming convention
- Simple to implement in bash loop

**Alternatives considered:**
- YAML manifest mapping expr→json: Extra indirection, harder to add tests
- CUE struct with test cases: Back to the original problem of non-concrete exports

### D3: JSON comparison method - `jq -cS` vs plain `diff`

**Choice:** `jq -cS` for normalized comparison

**Rationale:**
- Handles field ordering differences (CUE doesn't guarantee JSON key order)
- Compact output (`-c`) + sorted keys (`-S`) = deterministic comparison
- `jq` is already used in catalog workflows (version task), so no new dependency

**Alternatives considered:**
- Plain diff: Fragile to field ordering changes
- Custom JSON normalizer: Reinventing `jq`

### D4: Test coverage - all 6 cases vs minimal

**Choice:** All 6 resource test cases (Deployment string+number, StatefulSet, DaemonSet, CronJob, Job)

**Rationale:**
- CronJob has different output path (`spec.jobTemplate.spec.template...`) — needs explicit coverage
- All 5 transformer types share `#ToK8sContainer` but have different wrappers — smoke test each
- Number normalization is the critical path, but string passthrough regression is cheap to verify
- Total test time <1s, negligible overhead

## Risks / Trade-offs

**[Risk]** Golden files become stale if transformer output format changes  
**→ Mitigation:** Fail loudly with clear diff output. Updating golden files is a single `cue export > file.json` command per case.

**[Risk]** `jq` dependency might not be available in all environments  
**→ Mitigation:** Add precondition check. Test runner already requires `yq`, so tooling expectations are established. Gracefully skip Layer 3 if `jq` missing (with warning).

**[Risk]** Hidden `_` field expressions might not be accessible via `cue export -e`  
**→ Mitigation:** Verified during implementation — `cue export -e '_testDeploymentWithNumberResources...'` works because expressions in same package can reference hidden fields.

**[Trade-off]** More test files to maintain  
**→ Accepted:** 12 new files (6 expr + 6 json) is manageable. Golden files are easier to review than inline assertions.

**[Trade-off]** Doesn't test non-resource transformer outputs (labels, annotations, etc.)  
**→ Accepted:** Resource normalization is the bug-prone area. Other fields are covered by structural tests.
