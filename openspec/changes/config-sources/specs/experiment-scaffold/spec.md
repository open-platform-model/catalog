## ADDED Requirements

### Requirement: Self-contained CUE module

The experiment SHALL be a single CUE module at `experiments/001-config-sources/` that contains all definitions needed to evaluate, validate, and test config sources without any registry dependencies.

#### Scenario: Module evaluates without registry

- **WHEN** `cue vet ./...` is run in the experiment directory
- **THEN** it SHALL pass without requiring `CUE_REGISTRY` or any remote module resolution

#### Scenario: Module contains all dependencies

- **WHEN** the experiment module is inspected
- **THEN** it SHALL contain CUE packages for: core definitions, schemas, resource definitions, and K8s provider transformers
- **AND** no `cue.mod/module.cue` dependency SHALL reference an external registry module

### Requirement: Package structure mirrors catalog

The experiment SHALL organize CUE packages to mirror the catalog's module structure, enabling changes to be ported back to the main catalog.

#### Scenario: Package layout

- **WHEN** the experiment directory is listed
- **THEN** it SHALL contain packages for `core/`, `schemas/`, `resources/`, `providers/`, and `examples/`
- **AND** definition names and package names SHALL match the main catalog conventions

### Requirement: Working examples

The experiment SHALL include at least one example component that demonstrates config source usage with env `from` references, covering both inline data sources and external references.

#### Scenario: Example with inline config and secret sources

- **WHEN** the example component is evaluated
- **THEN** it SHALL define at least one `type: "config"` source with inline data
- **AND** at least one `type: "secret"` source with inline data
- **AND** container env vars SHALL reference keys from those sources via `from`

#### Scenario: Example with external reference

- **WHEN** the example component is evaluated
- **THEN** it SHALL define at least one source with `externalRef`
- **AND** a container env var SHALL reference a key from that external source via `from`

#### Scenario: Example passes validation

- **WHEN** `cue vet ./...` is run in the experiment directory
- **THEN** all examples SHALL validate without errors
