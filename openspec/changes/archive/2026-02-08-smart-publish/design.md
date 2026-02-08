## Context

The catalog has 8 CUE modules in `v0/` with a clean DAG of dependencies. Publishing today is fully manual: pick modules, bump versions individually, publish all. There's no change detection, no cascade logic, and no dependency pin management. The entire publish flow will be implemented as a single inline bash script within a new `publish:smart` Taskfile task.

Current dependency graph:

```text
Layer 0 (roots):    core, schemas
Layer 1:            resources, policies
Layer 2:            traits
Layer 3:            blueprints, providers, examples
```

All module dependency pins live in `v0/<module>/cue.mod/module.cue` as CUE syntax: `"opmodel.dev/<dep>@v0": { v: "<version>" }`. These are not YAML/JSON — `yq` cannot edit them, so `sed` is required.

## Goals / Non-Goals

**Goals:**

- Single command `task publish:smart` that handles detect → cascade → bump → pin update → tidy → publish → tag
- Deterministic: same inputs always produce same outputs
- Safe: dry-run mode, fail-fast on errors
- Additive: existing `publish:local` and `publish:all:local` tasks remain unchanged

**Non-Goals:**

- Remote/CI publishing (this targets local registry only)
- Automatic MINOR/MAJOR detection from commit messages (bump type is manual input)
- Rollback automation (manual via git revert + re-publish)
- Parallel publishing (topological order requires sequential execution)

## Decisions

### 1. Single inline bash task (no external script)

All logic lives in the `publish:smart` task's `cmds` block as an inline bash script.

**Why**: Keeps the Taskfile self-contained. The logic is ~100 lines of bash, which is manageable. An external script would add a file and indirection for modest complexity savings.

**Alternatives considered**: External `scripts/publish-smart.sh` — rejected for simplicity; the Go template variable injection is cleaner inline.

### 2. Dependency graph encoded as `deps` string field in CATALOG_MODULES

Each module entry gains a `deps: "core schemas"` string field. Go templates inject these as bash variables at parse time: `DEPS_resources="core schemas"`. Bash uses indirect variable expansion (`${!dep_var}`) to access them.

**Why**: Space-separated strings avoid Go template list iteration complexity. The graph is small (8 modules) and rarely changes — encoding it in the Taskfile alongside the module list is the natural single source of truth.

**Alternatives considered**: Parsing `cue.mod/module.cue` at runtime — rejected because it adds CUE parsing complexity and the graph is static.

### 3. Git tags as baseline for change detection

Tags follow the convention `catalog/<module>/<version>` (e.g., `catalog/core/v0.1.1`). The diff command excludes `cue.mod/` to prevent cascaded pin updates from triggering false positives:

```bash
git diff --quiet "$tag" -- "v0/$module/" ":(exclude)v0/$module/cue.mod/"
```

**Why**: Git tags are conventional, built-in, and visible. No extra state files needed.

**Alternatives considered**: Content hashing stored in a file — more deterministic but adds a state file to track; git tags are sufficient for this use case.

### 4. Cascade via forward topo-order scan

Instead of walking the reverse dependency graph (which would require building a reverse adjacency list), iterate modules in their existing topological order. For each module, check if any of its deps are already in the AFFECTED set — if so, add it.

```bash
for module in "${MODULES[@]}"; do
  deps="${!dep_var}"
  for dep in $deps; do
    if is_affected "$dep"; then
      mark_affected "$module"
      break
    fi
  done
done
```

**Why**: Single pass, O(n*m) with n=8 modules. No need to build/store a reverse graph. The topo order is already defined by `CATALOG_MODULES`.

### 5. Dependency pin update via range-scoped sed

Update `v:` pins in `cue.mod/module.cue` using sed with range addressing:

```bash
sed -i '/"opmodel.dev\/'"$dep"'@v0":/,/}/ s/v: ".*"/v: "'"$new_ver"'"/' \
  "$V0_DIR/$path/cue.mod/module.cue"
```

This scopes the replacement to the block between the dep key and its closing `}`, avoiding accidental matches elsewhere. The CUE files have consistent formatting (enforced by `cue fmt`), so the pattern is reliable.

**Why**: Minimal dependencies (just sed). The CUE file format is stable and `cue fmt` enforces consistent indentation.

**Alternatives considered**: Writing a CUE script or using `cue mod edit` (no such command exists). A Go/Python script would be overkill for string replacement.

### 6. Per-module sequential loop: bump → pin update → tidy → publish → tag

The main loop processes one module at a time in topo order. For each affected module:

1. Bump version in `versions.yml` (via `yq`)
2. Update dep pins in `cue.mod/module.cue` (via `sed`)
3. Run `cue mod tidy` (resolves updated pins against registry)
4. Run `cue mod publish $VERSION`
5. Create git tag `catalog/$module/$VERSION`

Step 3 requires the module's dependencies to already be in the registry, which topo ordering guarantees.

### 7. All version bumps use the same TYPE

When `TYPE=minor` is specified, ALL affected modules get a minor bump. This keeps versions synchronized across the cascade. Mixed bump types (minor for the changed module, patch for cascaded dependents) would add complexity without clear benefit.

## Risks / Trade-offs

**[Partial publish on failure]** → If publishing fails mid-cascade, some modules will have new tags and versions while others won't. Mitigation: the next run will detect the unpublished modules as changed (no tag = changed) and resume correctly. The tags are only created after successful publish.

**[sed fragility]** → If `cue fmt` output changes format in a future CUE version, the sed pattern could break. Mitigation: the pattern is simple (`v: "..."` within a scoped block) and any breakage would be immediately visible as a failed `cue mod tidy`.

**[No uncommitted change detection]** → `git diff` against tags includes uncommitted work. A user could accidentally publish work-in-progress. Mitigation: dry-run mode shows what would be published. Users should commit before publishing.

**[Tag pollution]** → Each publish creates N tags (one per affected module). With frequent publishes, tags accumulate. Mitigation: tags are lightweight git objects and can be cleaned up with `git tag -d`. Not a real concern at this scale.
