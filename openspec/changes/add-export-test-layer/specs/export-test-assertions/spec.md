## ADDED Requirements

### Requirement: Test runner executes export assertions

The test runner SHALL execute `cue export` assertions as a third test layer after existing `cue vet -c` and `testdata/*.yaml` validation.

#### Scenario: Export assertions run after structural tests
- **WHEN** `task test MODULE=providers` is executed
- **THEN** Layer 3 export assertions run after Layer 1 (`cue vet -c -t test`) and Layer 2 (`testdata/*.yaml`) complete
- **AND** each `.expr` file in `testdata/export/` is evaluated via `cue export -e`
- **AND** the output is compared against the paired `.json` golden file

#### Scenario: Test fails when export output doesn't match golden file
- **WHEN** `cue export -e` output differs from the golden JSON file
- **THEN** the test SHALL fail with status code 1
- **AND** the failure output SHALL include the expression, expected JSON, and actual JSON

#### Scenario: Test passes when export output matches golden file
- **WHEN** `cue export -e` output matches the golden JSON file (after normalization)
- **THEN** the test SHALL pass and increment the PASSED counter

### Requirement: Golden files define expected transformer output

Each transformer test case SHALL have a `.expr` file containing the CUE expression to evaluate and a `.json` file containing the expected JSON output.

#### Scenario: Expression file contains single CUE path
- **WHEN** a `.expr` file exists at `testdata/export/<name>.expr`
- **THEN** it SHALL contain a single line with a CUE expression (e.g., `_testDeploymentWithNumberResources.output.spec.template.spec.containers[0].resources`)

#### Scenario: JSON golden file contains expected output
- **WHEN** a `.json` file exists at `testdata/export/<name>.json`
- **THEN** it SHALL contain the expected JSON output from evaluating the expression
- **AND** the JSON SHALL be valid and parseable by `jq`

### Requirement: JSON comparison is order-independent

JSON comparison SHALL use normalized comparison to handle field ordering differences.

#### Scenario: Golden file and output have different key ordering
- **WHEN** `cue export` produces JSON with keys in different order than the golden file
- **AND** the semantic content is identical
- **THEN** the test SHALL pass

#### Scenario: Comparison uses jq for normalization
- **WHEN** comparing export output to golden file
- **THEN** both SHALL be normalized via `jq -cS .` (compact + sorted keys)
- **AND** the normalized strings SHALL be compared

### Requirement: Export tests cover all transformer types

Export assertions SHALL verify all 5 transformer types (Deployment, StatefulSet, DaemonSet, CronJob, Job) with both string and number resource inputs.

#### Scenario: Deployment with string resources
- **WHEN** transformer processes container with string resources (`"100m"`, `"256Mi"`)
- **THEN** `cue export` output SHALL match golden file with resources unchanged

#### Scenario: Deployment with number resources
- **WHEN** transformer processes container with number resources (`2`, `8`, `0.5`, `4`)
- **THEN** `cue export` output SHALL match golden file with normalized resources (`"2"`, `"8"`, `"512Mi"`, `"4Gi"`)

#### Scenario: StatefulSet resources validated
- **WHEN** StatefulSet transformer processes container with resources
- **THEN** `cue export` of `_testSSRes.output.spec.template.spec.containers[0].resources` SHALL match golden file

#### Scenario: DaemonSet resources validated
- **WHEN** DaemonSet transformer processes container with resources
- **THEN** `cue export` of `_testDSRes.output.spec.template.spec.containers[0].resources` SHALL match golden file

#### Scenario: CronJob resources validated
- **WHEN** CronJob transformer processes container with resources
- **THEN** `cue export` of `_testCJRes.output.spec.jobTemplate.spec.template.spec.containers[0].resources` SHALL match golden file

#### Scenario: Job resources validated
- **WHEN** Job transformer processes container with resources
- **THEN** `cue export` of `_testJRes.output.spec.template.spec.containers[0].resources` SHALL match golden file

### Requirement: Missing jq dependency is handled gracefully

The test runner SHALL check for `jq` availability and provide clear feedback if missing.

#### Scenario: jq is available
- **WHEN** `command -v jq` returns successfully
- **THEN** Layer 3 export assertions SHALL execute normally

#### Scenario: jq is not available
- **WHEN** `command -v jq` fails
- **THEN** Layer 3 export assertions SHALL be skipped
- **AND** a warning SHALL be printed: "jq not found, skipping Layer 3 export assertions"
- **AND** the overall test result SHALL not fail due to missing jq
