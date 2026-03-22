# AGENTS.md - Catalog repository guide

## Purpose

This repository exists to define and publish the Open Platform Model catalog as versioned CUE modules.
It is the source of truth for the catalog's reusable definitions and supporting artifacts, with most changes happening in `v1alpha1/`, documentation, and OpenSpec files.

## Repository Rules

- Repo-specific guidance comes from this file, `CONSTITUTION.md`, and the Taskfiles.
- Keep changes small; split broad requests into tiny steps.

## Entrypoint

Read these documents when entering this repository:

- Read `CONSTITUTION.md` before changing implementation.
- Read `docs/STYLE.md` before writing or editing documentation.
- Keep `v1alpha1/INDEX.md` updated when adding, removing, or renaming definitions.
  When updating `v1alpha1/INDEX.md`:
  1. Add a row to the correct section table for every new exported definition (`#Name`).
  2. Remove or rename rows whenever a definition is deleted or renamed.
  3. If a new `.cue` file doesn't fit an existing section, add a new `###` subsection in the correct `##` group.
  4. Keep file paths relative to `v1alpha1/` (e.g. `core/bundle/bundle.cue`, not an absolute path).
  5. Keep the Project Structure tree in sync with any new or removed directories.

## Repository Layout

```text
v1alpha1/
  core/                Base constructs and primitives
  schemas/             Shared schemas and Kubernetes schema mirrors
  resources/           Resource definitions
  traits/              Trait definitions
  blueprints/          Blueprint definitions
  providers/           Providers and transformers
  examples/            Example definitions validated separately
openspec/              Change proposals, designs, specs, tasks, constitution
.tasks/                Shared Taskfile fragments
versions.yml           Published module version + checksum
```

## Environment Notes

- `v1alpha1/cue.mod/module.cue` requires CUE `v0.15.0` or later.
- Local environment currently has `cue v0.16.0`.
- Task commands set `CUE_REGISTRY` automatically.
- When running raw `cue` commands outside `task`, export:

```bash
export OPM_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
export CUE_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
```

## Build And Dev Commands

Primary workflows are implemented in `Taskfile.yml`.

### Common Commands

- `task fmt` - run `cue fmt ./...` in `v1alpha1/`
- `task vet` - validate `core/`, `schemas/`, `resources/`, `traits/`, `blueprints/`, and `providers/`
- `task vet CONCRETE=true` - same as above, with `cue vet -c`
- `task vet:examples` - validate `v1alpha1/examples/` separately
- `task vet:examples CONCRETE=true` - validate examples with concreteness checks
- `task test` - run the repository test harness for CUE tests and fixtures
- `task eval` - evaluate all CUE under `v1alpha1/`
- `task eval OUTPUT=out.cue` - write evaluation output to a file
- `task tidy` - run `cue mod tidy` in `v1alpha1/`
- `task check` - run `task fmt` then `task vet`

### Single-Test Workflows

There is no dedicated single-test Task target yet. Use raw `cue` commands.

- Run one positive CUE test package:

```bash
cd v1alpha1
cue vet -c -t test ./resources/extension/...
```

- Run one specific `*_tests.cue` file with its package:

```bash
cd v1alpha1
cue vet -c -t test ./resources/extension/... ./resources/extension/crd_tests.cue
```

- Run one data fixture against one definition when `testdata/` fixtures exist:

```bash
cd v1alpha1
cue vet -d '#DefinitionName' ./... path/to/testdata/example_valid_case.yaml
```

- Fixture naming conventions:
  - `*_valid_*.yaml` or `*.json` must pass
  - `*_invalid_*.yaml` or `*.json` must fail

## Test Model Used Here

- Layer 1: `*_tests.cue` files tagged with `@if(test)` run through `cue vet -c -t test ./...`
- Layer 2: `testdata/*.yaml` and `testdata/*.json` run through `cue vet -d '#Definition'`
- Hidden test fields like `_testSomething` are the normal assertion style
- Exported test fields are avoided unless a test intentionally depends on concreteness

## CUE Style Guidelines

### Core Syntax

- Use `#` prefixes for definitions: `#Module`, `#ContainerResource`, `#ScalingTrait`
- Use `_` prefixes for hidden fields and scratch bindings: `_secrets`, `_allFields`, `let _k8sName = ...`
- Use `!` for required fields and `?` for optional fields
- Use `*` defaults for explicit defaults
- Prefer `close({...})` for component, resource, and trait specs that should reject unknown fields
- Keep definitions declarative; avoid imperative or runtime-oriented logic

### Packages and File Organization

- Package names are short, lowercase, and domain-scoped: `module`, `schemas`, `workload`, `transformers`
- Group definitions by domain directory, not by file type alone
- Follow existing filenames such as `container.cue`, `scaling.cue`, `secret_transformer.cue`
- Keep tests near the definitions they exercise when using `*_tests.cue`

### Imports

- Use import blocks when the file already follows that style
- Alias imports when it improves clarity or avoids collisions: `prim`, `schemas`, `k8scorev1`
- Keep aliases short and semantic
- Prefer stable package-level aliases for reused imported definitions when CUE import tracking needs it

### Naming

- Definition names use PascalCase with a `#` prefix
- Resource and trait definition names often end in `Resource`, `Trait`, `Defaults`, or a transformer suffix
- Metadata `name` values use kebab-case strings
- Map keys are descriptive and often reused as defaults with `name: string | *key`
- Hidden test names use `_test...`

### Schema Design

- Reuse shared schemas from `opmodel.dev/schemas@v1` instead of duplicating constraints
- Compose via unification rather than copying fields
- Keep module, resource, trait, and blueprint boundaries clear
- Express intent as schemas and constraints, not procedural validation steps
- Preserve runtime agnosticism except inside provider-specific transformers

### Types and Constraints

- Prefer precise schema types over `_`
- Use regex, list, and string constraints for structural validation
- Use comprehensions and `let` bindings to compute derived values clearly
- Keep schemas OpenAPI-compatible where comments require OpenAPIv3 compatibility
- Use deterministic computed fields for FQNs, UUIDs, and generated names

### Error Handling and Validation

- Prefer failing by constraint and unification rather than loose schemas
- Use `cue vet -c` when checking that values are concrete, not just structurally valid
- Use `error()` for custom validation messages when a plain conflict would be unclear
- Reject invalid configuration at definition time; do not defer validation to runtime consumers

### Comments and Documentation

- Add comments when intent, dispatch logic, or naming is non-obvious
- Keep comments technical and specific; avoid narrating trivial assignments
- Preserve existing section-separator styles where present
- In Markdown diagrams and tables, use ASCII-safe markers like `[x]`, `[ ]`, `OK`, `FAIL`; do not use Unicode checkmarks

## Change Discipline

- Validate with `task fmt` and `task vet` before considering work done
- Use `task vet CONCRETE=true` when changing value-producing definitions or tests that depend on concreteness
- Run `task vet:examples` if a change can affect examples or top-level composition
- Update `versions.yml` only when intentionally doing version-management work
- Do not introduce unrelated cleanup in touched files unless it directly helps the change

## Commit Guidance

- Follow Conventional Commits: `type(scope): description`
- Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- Use the module or domain as scope when helpful: `feat(core): ...`, `fix(traits): ...`
- For OpenSpec work, use change-related commit naming from the repository constitution
- Never add AI attribution to commit messages
