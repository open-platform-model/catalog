## ADDED Requirements

### Requirement: OPM secrets component generated in CUE

The catalog SHALL define `#OpmSecretsComponent` in `v1alpha1/core/helpers/autosecrets.cue` that builds a `#Component` from auto-discovered secret data. When a module's `#config` schema contains `#Secret` fields, `#ModuleRelease` SHALL auto-generate an `"opm-secrets"` component in its `components` map using this helper.

#### Scenario: Module with secrets in config
- **WHEN** a `#ModuleRelease` references a module whose `#config` contains `#Secret` fields
- **THEN** the release's `components` map SHALL include an `"opm-secrets"` entry built by `#OpmSecretsComponent`

#### Scenario: Module with no secrets
- **WHEN** a `#ModuleRelease` references a module whose `#config` contains no `#Secret` fields
- **THEN** no `"opm-secrets"` component SHALL be added to the `components` map

### Requirement: SecretsResourceFQN constant

`v1alpha1/core/helpers/` SHALL define `#SecretsResourceFQN` as the canonical FQN string for the secrets resource (`"opmodel.dev/resources/config/secrets@v1"`). This constant MUST stay in sync with the FQN defined in `v1alpha1/resources/config/secret.cue`.

#### Scenario: FQN matches resource definition
- **WHEN** `#SecretsResourceFQN` is compared to `#SecretsResource.metadata.fqn`
- **THEN** they SHALL be identical strings

### Requirement: Import cycle resolved

The `core/helpers/` package SHALL NOT import `resources/config/`. It SHALL import `core/component/` and `schemas/` to construct the secrets component without creating a circular dependency.

#### Scenario: CUE evaluation succeeds without import cycle
- **WHEN** `cue vet ./...` is run on `v1alpha1/`
- **THEN** no import cycle errors SHALL be reported involving `core/helpers/`

### Requirement: AutoSecrets field is hidden

`#ModuleRelease` SHALL compute auto-discovered secrets as `_autoSecrets` (hidden/private field), not as a public `autoSecrets` field. The opm-secrets component is generated inline in the `components` map.

#### Scenario: autoSecrets not exposed in evaluation output
- **WHEN** a `#ModuleRelease` is evaluated
- **THEN** no public `autoSecrets` field SHALL appear in the output
