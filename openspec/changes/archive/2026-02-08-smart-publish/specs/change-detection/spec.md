## ADDED Requirements

### Requirement: Baseline tagging convention

The system SHALL use git tags with the format `catalog/<module>/<version>` as the baseline for change detection. Each tag represents the last successfully published state of a module.

#### Scenario: Tag created after successful publish

- **WHEN** a module is successfully published
- **THEN** a git tag `catalog/<module>/<version>` SHALL be created (e.g., `catalog/core/v0.1.1`)

#### Scenario: Tag format is consistent

- **WHEN** a tag is created for module `core` at version `v0.2.0`
- **THEN** the tag name SHALL be exactly `catalog/core/v0.2.0`

### Requirement: Detect changed modules via git diff

The system SHALL detect which modules have source changes by running `git diff` between the current working tree and the module's baseline tag.

#### Scenario: Module has changes since last publish

- **WHEN** files under `v0/<module>/` (excluding `cue.mod/`) differ from the baseline tag `catalog/<module>/<current_version>`
- **THEN** the module SHALL be marked as changed

#### Scenario: Module has no changes

- **WHEN** files under `v0/<module>/` (excluding `cue.mod/`) are identical to the baseline tag
- **THEN** the module SHALL NOT be marked as changed

#### Scenario: Only cue.mod files changed

- **WHEN** the only changes under `v0/<module>/` are within `cue.mod/`
- **THEN** the module SHALL NOT be marked as changed (pin updates are not source changes)

### Requirement: First-run detection without tags

The system SHALL treat a module as changed when no baseline tag exists for it.

#### Scenario: No tag exists for a module

- **WHEN** no git tag matching `catalog/<module>/*` exists for a module
- **THEN** the module SHALL be marked as changed

### Requirement: Dry-run mode

The system SHALL support a dry-run mode that reports which modules are detected as changed without performing any mutations.

#### Scenario: Dry run reports changes

- **WHEN** `DRY_RUN=true` is set
- **THEN** the system SHALL print which modules are detected as changed and exit without modifying any files, publishing, or creating tags
