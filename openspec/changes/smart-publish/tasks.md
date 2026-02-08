## 1. Extend CATALOG_MODULES with dependency graph

- [x] 1.1 Add `deps` field to each module entry in `CATALOG_MODULES` (space-separated string of dependency names, empty string for root modules)
- [x] 1.2 Remove `desc` field from `CATALOG_MODULES` entries (no longer used, keeps entries concise)

## 2. Implement `publish:smart` task

- [x] 2.1 Add task definition with `DRY_RUN` and `TYPE` vars, `yq`/`cue`/`git` preconditions
- [x] 2.2 Generate bash variables from Go templates: `MODULES` array, `PATHS` array, `DEPS_<name>` and `MOD_FQN_<name>` per module
- [x] 2.3 Implement helper functions: `get_version`, `bump_version`, `is_affected`, `mark_affected`
- [x] 2.4 Implement Phase 1 — change detection: for each module, resolve baseline tag `catalog/<module>/<version>`, run `git diff --quiet` excluding `cue.mod/`, handle missing tags as "changed"
- [x] 2.5 Implement Phase 2 — cascade computation: iterate modules in topo order, if any dep is in AFFECTED set then add module to AFFECTED set
- [x] 2.6 Implement Phase 3 — per-module loop (topo order): bump version in `versions.yml` via `yq`, update dep pins in `cue.mod/module.cue` via range-scoped `sed`, run `cue mod tidy`, run `cue mod publish`, create git tag
- [x] 2.7 Implement dry-run mode: when `DRY_RUN=true`, print detected changes, cascade result, and planned actions, then exit without mutations
- [x] 2.8 Implement no-op exit: when no modules detected as changed, print message and exit 0

## 3. Validation

- [x] 3.1 Run `task fmt` to verify Taskfile formatting
- [x] 3.2 Run `task publish:smart DRY_RUN=true` to verify change detection and cascade logic against current repo state
- [ ] 3.3 Run `task publish:smart` end-to-end against local registry to verify full flow
