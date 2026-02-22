## 1. Setup test directory structure

- [ ] 1.1 Create `v0/providers/kubernetes/transformers/testdata/export/` directory
- [ ] 1.2 Verify `jq` is installed in dev environment (`command -v jq`)

## 2. Generate golden files for all transformer types

- [ ] 2.1 Export Deployment string resources: `cue export -e '_testDeploymentWithTraits.output.spec.template.spec.containers[0].resources' v0/providers/kubernetes/transformers/ > v0/providers/kubernetes/transformers/testdata/export/deploy-string-resources.json`
- [ ] 2.2 Create expression file: `echo '_testDeploymentWithTraits.output.spec.template.spec.containers[0].resources' > v0/providers/kubernetes/transformers/testdata/export/deploy-string-resources.expr`
- [ ] 2.3 Export Deployment number resources: `cue export -e '_testDeploymentWithNumberResources.output.spec.template.spec.containers[0].resources' v0/providers/kubernetes/transformers/ > v0/providers/kubernetes/transformers/testdata/export/deploy-number-resources.json`
- [ ] 2.4 Create expression file: `echo '_testDeploymentWithNumberResources.output.spec.template.spec.containers[0].resources' > v0/providers/kubernetes/transformers/testdata/export/deploy-number-resources.expr`
- [ ] 2.5 Export StatefulSet resources: `cue export -e '_testSSRes.output.spec.template.spec.containers[0].resources' v0/providers/kubernetes/transformers/ > v0/providers/kubernetes/transformers/testdata/export/statefulset-resources.json`
- [ ] 2.6 Create expression file: `echo '_testSSRes.output.spec.template.spec.containers[0].resources' > v0/providers/kubernetes/transformers/testdata/export/statefulset-resources.expr`
- [ ] 2.7 Export DaemonSet resources: `cue export -e '_testDSRes.output.spec.template.spec.containers[0].resources' v0/providers/kubernetes/transformers/ > v0/providers/kubernetes/transformers/testdata/export/daemonset-resources.json`
- [ ] 2.8 Create expression file: `echo '_testDSRes.output.spec.template.spec.containers[0].resources' > v0/providers/kubernetes/transformers/testdata/export/daemonset-resources.expr`
- [ ] 2.9 Export CronJob resources: `cue export -e '_testCJRes.output.spec.jobTemplate.spec.template.spec.containers[0].resources' v0/providers/kubernetes/transformers/ > v0/providers/kubernetes/transformers/testdata/export/cronjob-resources.json`
- [ ] 2.10 Create expression file: `echo '_testCJRes.output.spec.jobTemplate.spec.template.spec.containers[0].resources' > v0/providers/kubernetes/transformers/testdata/export/cronjob-resources.expr`
- [ ] 2.11 Export Job resources: `cue export -e '_testJRes.output.spec.template.spec.containers[0].resources' v0/providers/kubernetes/transformers/ > v0/providers/kubernetes/transformers/testdata/export/job-resources.json`
- [ ] 2.12 Create expression file: `echo '_testJRes.output.spec.template.spec.containers[0].resources' > v0/providers/kubernetes/transformers/testdata/export/job-resources.expr`

## 3. Implement Layer 3 in Taskfile test runner

- [ ] 3.1 Add jq precondition check at start of `run_module_tests` function (after color definitions)
- [ ] 3.2 Add Layer 3 loop after Layer 2 (testdata/*.yaml) loop and before `has_tests` check
- [ ] 3.3 Implement expression file discovery: `find "$mod_dir" -type f -name '*.expr' -path '*/testdata/export/*'`
- [ ] 3.4 Implement paired JSON file check: `jsonfile="${exprfile%.expr}.json"`
- [ ] 3.5 Implement `cue export -e` execution from module directory
- [ ] 3.6 Implement JSON normalization comparison using `jq -cS .`
- [ ] 3.7 Implement PASS output: `echo -e "  ${GREEN}PASS${RESET}  ${DIM}${name}${RESET} (export: ${CYAN}${expr}${RESET})"`
- [ ] 3.8 Implement FAIL output with expr/expected/actual diff
- [ ] 3.9 Set `has_tests=true` when export tests found
- [ ] 3.10 Increment PASSED/FAILED counters appropriately
- [ ] 3.11 Add errors to ERRORS string on failure

## 4. Validation and testing

- [ ] 4.1 Run `task test MODULE=providers` and verify Layer 3 executes
- [ ] 4.2 Verify all 6 export assertions pass
- [ ] 4.3 Intentionally break a golden file and verify test fails with clear diff
- [ ] 4.4 Restore golden file and verify test passes again
- [ ] 4.5 Test with `jq` unavailable (rename binary temporarily) and verify graceful skip
- [ ] 4.6 Run `task fmt` to ensure all files are formatted
- [ ] 4.7 Run `task vet MODULE=providers` to ensure all changes validate

## 5. Documentation

- [ ] 5.1 Add comment block at start of Layer 3 loop explaining purpose
- [ ] 5.2 Verify transformer_tests.cue comment references export tests in testdata/export/
