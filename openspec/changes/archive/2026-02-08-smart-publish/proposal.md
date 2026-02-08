## Why

Publishing catalog modules is currently a fully manual process: you decide which modules changed, bump versions one by one, and publish everything regardless of what actually changed. This is error-prone, slow, and doesn't handle the dependency cascade — when `core` changes, all downstream modules need their dependency pins updated, tidied, and re-published in topological order. A single `task publish:smart` should detect changes, compute the cascade, and handle the entire flow deterministically.

## What Changes

- Add `deps` field to each entry in `CATALOG_MODULES` to encode the dependency graph in the Taskfile
- Add `publish:smart` task that:
  - Detects which modules have source changes (git diff against per-module tags)
  - Computes the full transitive dependent cascade
  - Bumps PATCH version for all affected modules in `versions.yml`
  - Updates dependency pins (`v:` field) in each affected module's `cue.mod/module.cue`
  - Runs `cue mod tidy` on each affected module (after its deps are published)
  - Publishes each affected module via `cue mod publish` in topological order
  - Creates git tags (`catalog/<module>/<version>`) as the baseline for future diffs
- Support `DRY_RUN=true` to preview what would happen without executing
- Support `TYPE=minor|major` to override the default patch bump

## Capabilities

### New Capabilities

- `change-detection`: Detect which modules have source changes by comparing against git tags, excluding `cue.mod/` to avoid false positives from pin updates
- `cascade-publish`: Compute transitive dependents from the dependency graph, bump versions, update dependency pins, tidy, and publish in topological order

### Modified Capabilities

_(none)_

## Impact

- **Taskfile.yml**: `CATALOG_MODULES` gains a `deps` field; new `publish:smart` task added
- **versions.yml**: Automatically updated by the task (patch bumps)
- **v0/*/cue.mod/module.cue**: Dependency `v:` pins automatically updated via sed
- **Git tags**: New tagging convention `catalog/<module>/<version>` introduced
- **Existing tasks**: `publish:local` and `publish:all:local` remain unchanged (no breaking changes)
- **SemVer**: PATCH-level change to build tooling, no module API changes
