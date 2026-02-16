## ADDED Requirements

### Requirement: All definition names use kebab-case DNS labels

Every concrete `name` value in definition metadata across all modules SHALL be migrated from PascalCase to kebab-case format conforming to RFC 1123 DNS labels.

The conversion rule SHALL be: insert a hyphen before each uppercase letter boundary, then lowercase the entire string. Examples:

- `"StatelessWorkload"` → `"stateless-workload"`
- `"Container"` → `"container"`
- `"CronJobConfig"` → `"cron-job-config"`
- `"PVCTransformer"` → `"pvc-transformer"`
- `"SimpleDatabase"` → `"simple-database"`

#### Scenario: Resource definition names migrated

- **WHEN** inspecting resource definitions in `v0/resources/`
- **THEN** names like `"Container"`, `"Volumes"`, `"Expose"` SHALL be `"container"`, `"volumes"`, `"expose"`

#### Scenario: Trait definition names migrated

- **WHEN** inspecting trait definitions in `v0/traits/`
- **THEN** names like `"Replicas"`, `"UpdateStrategy"`, `"SidecarContainers"` SHALL be `"replicas"`, `"update-strategy"`, `"sidecar-containers"`

#### Scenario: Blueprint definition names migrated

- **WHEN** inspecting blueprint definitions in `v0/blueprints/`
- **THEN** names like `"StatelessWorkload"`, `"DaemonWorkload"` SHALL be `"stateless-workload"`, `"daemon-workload"`

#### Scenario: Policy definition names migrated

- **WHEN** inspecting policy definitions in `v0/policies/`
- **THEN** names like `"SharedNetwork"`, `"NetworkRules"` SHALL be `"shared-network"`, `"network-rules"`

#### Scenario: Transformer definition names migrated

- **WHEN** inspecting transformer definitions in `v0/providers/`
- **THEN** names like `"DeploymentTransformer"`, `"ServiceTransformer"` SHALL be `"deployment-transformer"`, `"service-transformer"`

#### Scenario: Module definition names migrated

- **WHEN** inspecting module definitions in `v0/examples/`
- **THEN** names like `"BasicModule"`, `"MultiTierModule"` SHALL be `"basic-module"`, `"multi-tier-module"`

### Requirement: FQN values computed via _definitionName

All computed `fqn` fields SHALL use the `_definitionName` hidden field (kebab→PascalCase conversion) for interpolation. The resulting FQN values will reflect the PascalCase conversion of the new kebab-case names.

Acronym segments that were previously all-caps (e.g., `PVC`) will become first-letter-capitalized (e.g., `Pvc`) since the conversion is mechanical.

| kebab-case name | `_definitionName` | FQN name segment |
|---|---|---|
| `"container"` | `"Container"` | `#Container` |
| `"stateless-workload"` | `"StatelessWorkload"` | `#StatelessWorkload` |
| `"pvc-transformer"` | `"PvcTransformer"` | `#PvcTransformer` |
| `"cron-job-config"` | `"CronJobConfig"` | `#CronJobConfig` |

#### Scenario: Simple name FQN unchanged

- **WHEN** a resource has `name: "container"` and `apiVersion: "opmodel.dev/resources/workload@v0"`
- **THEN** `_definitionName` SHALL be `"Container"` and `fqn` SHALL be `"opmodel.dev/resources/workload@v0#Container"`

#### Scenario: Multi-word name FQN preserved

- **WHEN** a blueprint has `name: "stateless-workload"` and `apiVersion: "opmodel.dev/blueprints@v0"`
- **THEN** `_definitionName` SHALL be `"StatelessWorkload"` and `fqn` SHALL be `"opmodel.dev/blueprints@v0#StatelessWorkload"`

#### Scenario: Acronym FQN changes

- **WHEN** a transformer has `name: "pvc-transformer"` and `apiVersion: "opmodel.dev/providers/kubernetes/transformers@v0"`
- **THEN** `_definitionName` SHALL be `"PvcTransformer"` and `fqn` SHALL be `"opmodel.dev/providers/kubernetes/transformers@v0#PvcTransformer"` (changed from `#PVCTransformer`)

### Requirement: All FQN references in components updated

Every place a definition is referenced by its FQN string (e.g., as map keys in `#resources`, `#traits`, `#blueprints`) SHALL be updated to use the new FQN values derived from `_definitionName`.

#### Scenario: Component resource map keys updated

- **WHEN** a component references a resource by FQN key
- **THEN** the key SHALL match the definition's computed `fqn` (e.g., `"opmodel.dev/resources/workload@v0#Container"`)

#### Scenario: Component trait map keys updated

- **WHEN** a component references a trait by FQN key
- **THEN** the key SHALL match the definition's computed `fqn` (e.g., `"opmodel.dev/traits/workload@v0#Replicas"`)

### Requirement: Test fixtures and examples updated

All test fixtures (prefixed with `_test`) and example definitions SHALL be updated to use kebab-case names that pass `#NameType` validation.

#### Scenario: Core test module updated

- **WHEN** inspecting `_testModule` in `v0/core/module.cue`
- **THEN** `metadata.name` SHALL be a kebab-case value like `"test-module"` instead of `"TestModule"`

#### Scenario: Core test component updated

- **WHEN** inspecting `_testComponent` in `v0/core/component.cue`
- **THEN** resource and trait FQN keys SHALL use the `_definitionName`-derived FQN values

#### Scenario: Example modules updated

- **WHEN** inspecting example modules in `v0/examples/modules/`
- **THEN** all `metadata.name` values SHALL be kebab-case
