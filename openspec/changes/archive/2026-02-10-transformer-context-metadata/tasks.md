## 1. Core module — transformer label filtering

- [x] 1.1 Add `"strings"` import to `v0/core/transformer.cue`
- [x] 1.2 Add `strings.HasPrefix` filter to `componentLabels` comprehension to exclude `transformer.opmodel.dev/*` keys
- [x] 1.3 Add `strings.HasPrefix` filter to `componentAnnotations` comprehension to exclude `transformer.opmodel.dev/*` keys
- [x] 1.4 Run `task vet MODULE=core` to validate

## 2. Core module — publish and cascade

- [x] 2.1 Run `task fmt MODULE=core`
- [x] 2.2 Publish updated `core` module to local registry
- [x] 2.3 Run `task tidy` on all downstream modules (schemas, resources, traits, blueprints, policies, providers, examples)

## 3. Providers module — update test fixtures

- [x] 3.1 Update `_testContext` in `v0/providers/kubernetes/transformers/test_data.cue`: replace `#moduleMetadata` with `#moduleReleaseMetadata: core._testModuleRelease.metadata`
- [x] 3.2 Update `_testContext` in `test_data.cue`: replace freeform `#componentMetadata` with `core._testComponent.metadata`
- [x] 3.3 Run `task vet MODULE=providers` to validate

## 4. Validation

- [x] 4.1 Run `task fmt` on all modules
- [x] 4.2 Run `task vet` on all modules
- [x] 4.3 Run `task eval MODULE=providers` and verify identity labels (`module.opmodel.dev/uuid`, `module-release.opmodel.dev/uuid`) appear in rendered output labels
- [x] 4.4 Run `task eval MODULE=providers` and verify `transformer.opmodel.dev/*` keys are absent from rendered `componentLabels` and `componentAnnotations`
- [x] 4.5 Run `task eval MODULE=examples` and verify identity labels propagate to example module releases
