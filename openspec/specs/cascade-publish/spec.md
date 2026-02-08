# Cascade Publish

## Purpose

Compute transitive dependents from the module dependency graph, bump versions, update dependency pins, tidy, and publish affected modules in topological order.

## Requirements

### Requirement: Dependency graph in Taskfile

The `CATALOG_MODULES` variable SHALL include a `deps` field on each module entry encoding its direct dependencies as a space-separated string.

#### Scenario: Module with dependencies

- **WHEN** a module depends on `core` and `schemas`
- **THEN** its entry SHALL have `deps: "core schemas"`

#### Scenario: Module with no dependencies

- **WHEN** a module has no dependencies (e.g., `core`, `schemas`)
- **THEN** its entry SHALL have `deps: ""`

### Requirement: Transitive dependent cascade

The system SHALL compute the full set of affected modules by walking the reverse dependency graph from each changed module, collecting all transitive dependents.

#### Scenario: Root module changes

- **WHEN** `core` is detected as changed
- **THEN** all modules that depend on `core` directly or transitively SHALL be included in the affected set

#### Scenario: Leaf module changes

- **WHEN** `policies` is detected as changed (nothing depends on it)
- **THEN** only `policies` SHALL be in the affected set

#### Scenario: Mid-graph module changes

- **WHEN** `resources` is detected as changed
- **THEN** `resources`, `traits`, `blueprints`, `providers`, and `examples` SHALL be in the affected set (but NOT `core`, `schemas`, or `policies`)

### Requirement: Topological ordering

All operations on affected modules (bump, pin update, tidy, publish) SHALL be performed in topological order as defined by the `CATALOG_MODULES` sequence.

#### Scenario: Publishing respects dependency order

- **WHEN** `core` and `traits` are both in the affected set
- **THEN** `core` SHALL be bumped, tidied, and published before `traits`

### Requirement: Version bump in versions.yml

The system SHALL bump the version in `versions.yml` for every module in the affected set.

#### Scenario: Patch bump (default)

- **WHEN** `TYPE` is not specified or is `patch`
- **THEN** the PATCH component SHALL be incremented (e.g., `v0.1.0` → `v0.1.1`)

#### Scenario: Minor bump

- **WHEN** `TYPE=minor` is specified
- **THEN** the MINOR component SHALL be incremented and PATCH reset to 0 (e.g., `v0.1.2` → `v0.2.0`)

#### Scenario: Major bump

- **WHEN** `TYPE=major` is specified
- **THEN** the MAJOR component SHALL be incremented and MINOR/PATCH reset to 0

### Requirement: Dependency pin update

The system SHALL update the `v:` field in each affected module's `cue.mod/module.cue` to match the new version of any bumped dependency.

#### Scenario: Upstream dependency was bumped

- **WHEN** `core` is bumped from `v0.1.0` to `v0.1.1` and `resources` depends on `core`
- **THEN** `v0/resources/cue.mod/module.cue` SHALL be updated so that `"opmodel.dev/core@v0": { v: "v0.1.1" }`

#### Scenario: Non-affected dependency is unchanged

- **WHEN** `schemas` was NOT bumped and `resources` depends on `schemas`
- **THEN** the `schemas` pin in `v0/resources/cue.mod/module.cue` SHALL remain unchanged

### Requirement: Tidy after pin update

The system SHALL run `cue mod tidy` on each affected module after its dependency pins are updated and after all of its dependencies have been published to the registry.

#### Scenario: Tidy runs after upstream publish

- **WHEN** `resources` depends on `core` and both are affected
- **THEN** `core` SHALL be published first, then `cue mod tidy` SHALL run in `v0/resources/` before `resources` is published

### Requirement: Publish to registry

The system SHALL run `cue mod publish <version>` for each affected module using the newly bumped version from `versions.yml`.

#### Scenario: Successful publish

- **WHEN** a module is affected and its dependencies are already published
- **THEN** `cue mod publish` SHALL be invoked with the new version

#### Scenario: Publish failure aborts

- **WHEN** `cue mod publish` fails for any module
- **THEN** the system SHALL stop and exit with a non-zero status

### Requirement: No-op when nothing changed

The system SHALL exit cleanly when no modules are detected as changed.

#### Scenario: No changes detected

- **WHEN** no modules have source changes relative to their baseline tags
- **THEN** the system SHALL print a message indicating nothing to publish and exit with status 0
